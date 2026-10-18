package com.log.diverr.diver.divelogs.usecases;

import com.log.diverr.diver.common.ApiException;
import com.log.diverr.diver.common.RatingRules;
import com.log.diverr.diver.divelogs.domain.DiveLogImageModel;
import com.log.diverr.diver.divelogs.domain.DiveLogModel;
import com.log.diverr.diver.divelogs.dtos.CreateDiveLogDto;
import com.log.diverr.diver.divelogs.dtos.DiveLogResponseDto;
import com.log.diverr.diver.divelogs.repository.DiveLogRepository;
import com.log.diverr.diver.divesites.domain.DiveSiteModel;
import com.log.diverr.diver.divesites.repository.DiveSiteRepository;
import com.log.diverr.diver.lists.DiveListService;
import com.log.diverr.diver.plans.PlanService;
import com.log.diverr.diver.reviews.DiveSiteReviewService;
import com.log.diverr.diver.social.DiveLogCommentRepository;
import com.log.diverr.diver.social.DiveLogReactionRepository;
import com.log.diverr.diver.social.VisibilityService;
import com.log.diverr.diver.storage.ImageStorageService;
import com.log.diverr.diver.storage.PresignRequestDto;
import com.log.diverr.diver.storage.PresignResponseDto;
import com.log.diverr.diver.users.domain.UserModel;
import com.log.diverr.diver.users.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * CRUD dos mergulhos. Escrita é sempre do dono (userId do token).
 * Leitura de mergulhos de OUTRAS pessoas passa pela privacidade (VisibilityService).
 * Mergulho que o usuário não pode ver responde 404 (não revela que existe).
 */
@Service
public class DiveLogService {

    private final DiveLogRepository diveLogRepository;
    private final UserRepository userRepository;
    private final DiveSiteRepository diveSiteRepository;
    private final PlanService planService;
    private final ImageStorageService storage;
    private final VisibilityService visibility;
    private final DiveSiteReviewService reviewService;
    private final DiveLogReactionRepository reactions;
    private final DiveLogCommentRepository comments;
    private final DiveListService listService;

    public DiveLogService(
            DiveLogRepository diveLogRepository,
            UserRepository userRepository,
            DiveSiteRepository diveSiteRepository,
            PlanService planService,
            ImageStorageService storage,
            VisibilityService visibility,
            DiveSiteReviewService reviewService,
            DiveLogReactionRepository reactions,
            DiveLogCommentRepository comments,
            DiveListService listService
    ) {
        this.diveLogRepository = diveLogRepository;
        this.userRepository = userRepository;
        this.diveSiteRepository = diveSiteRepository;
        this.planService = planService;
        this.storage = storage;
        this.visibility = visibility;
        this.reviewService = reviewService;
        this.reactions = reactions;
        this.comments = comments;
        this.listService = listService;
    }

    // ---------------- leitura ----------------

    @Transactional(readOnly = true)
    public List<DiveLogResponseDto> listMine(Long userId) {
        return diveLogRepository.findByUserIdOrderByDataHoraDesc(userId).stream()
                .map(l -> DiveLogResponseDto.from(l, storage)).toList();
    }

    /** Mergulhos de outro usuário, respeitando a privacidade dele. */
    @Transactional(readOnly = true)
    public List<DiveLogResponseDto> listOfUser(Long ownerId, Long viewerId) {
        UserModel owner = userRepository.findById(ownerId)
                .orElseThrow(() -> ApiException.notFound("Usuário não encontrado"));
        if (!visibility.canViewDives(viewerId, owner)) {
            throw ApiException.forbidden("Este usuário não compartilha os mergulhos com você");
        }
        return diveLogRepository.findByUserIdOrderByDataHoraDesc(ownerId).stream()
                .map(l -> DiveLogResponseDto.from(l, storage)).toList();
    }

    @Transactional(readOnly = true)
    public List<DiveLogResponseDto> listMineBySite(UUID siteId, Long userId) {
        return diveLogRepository.findByDiveSiteIdAndUserIdOrderByDataHoraDesc(siteId, userId).stream()
                .map(l -> DiveLogResponseDto.from(l, storage)).toList();
    }

    @Transactional(readOnly = true)
    public DiveLogResponseDto get(UUID id, Long viewerId) {
        DiveLogModel log = diveLogRepository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Dive log não encontrado"));
        boolean owner = log.getUser().getId().equals(viewerId);
        if (!owner && !visibility.canViewDives(viewerId, log.getUser())) {
            throw ApiException.notFound("Dive log não encontrado");
        }
        return DiveLogResponseDto.from(log, storage);
    }

    // ---------------- escrita ----------------

    @Transactional
    public DiveLogResponseDto create(CreateDiveLogDto dto, Long userId) {
        UserModel user = userRepository.findById(userId)
                .orElseThrow(() -> ApiException.unauthorized("Usuário não encontrado"));

        // idempotência: o app offline pode reenviar o mesmo mergulho (clientId) após uma falha de rede
        if (dto.clientId() != null) {
            var existing = diveLogRepository.findByUserIdAndClientId(userId, dto.clientId());
            if (existing.isPresent()) {
                return DiveLogResponseDto.from(existing.get(), storage);
            }
        }

        DiveSiteModel site = activeSite(dto.diveSiteId());
        validateRules(dto);

        DiveLogModel log = new DiveLogModel();
        log.setUser(user);
        log.setDiveSite(site);
        apply(log, dto);

        log.setClientId(dto.clientId());

        DiveLogModel saved = diveLogRepository.saveAndFlush(log);
        // a nota/comentário do local viram a avaliação do usuário no Dive Site
        reviewService.upsertFromDive(site.getId(), userId, dto.notaLocal(), dto.comentarioLocal());
        // o local passa a constar em "Já mergulhei" e sai de "Quero mergulhar"
        listService.markVisitedFromDive(userId, site.getId());
        return DiveLogResponseDto.from(saved, storage);
    }

    @Transactional
    public DiveLogResponseDto update(UUID id, CreateDiveLogDto dto, Long userId) {
        DiveLogModel log = findOwned(id, userId);
        validateRules(dto);

        // só exige site ativo se o mergulho mudou de local (mergulhos antigos em locais desativados continuam editáveis)
        if (!log.getDiveSite().getId().equals(dto.diveSiteId())) {
            log.setDiveSite(activeSite(dto.diveSiteId()));
        }
        apply(log, dto);

        DiveLogModel saved = diveLogRepository.saveAndFlush(log);
        reviewService.upsertFromDive(saved.getDiveSite().getId(), userId, dto.notaLocal(), dto.comentarioLocal());
        listService.markVisitedFromDive(userId, saved.getDiveSite().getId());
        return DiveLogResponseDto.from(saved, storage);
    }

    @Transactional
    public void delete(UUID id, Long userId) {
        DiveLogModel log = findOwned(id, userId);
        List<String> keys = log.getImages().stream().map(DiveLogImageModel::getStorageKey).toList();

        // reações e comentários referenciam o mergulho: removê-los antes
        reactions.deleteByDiveLogId(id);
        comments.deleteByDiveLogId(id);
        diveLogRepository.flush();

        diveLogRepository.delete(log);
        diveLogRepository.flush();
        keys.forEach(storage::delete);
    }

    // ---------------- imagens ----------------

    @Transactional(readOnly = true)
    public PresignResponseDto presignImage(UUID id, Long userId, PresignRequestDto req) {
        DiveLogModel log = findOwned(id, userId);
        planService.assertCanAddPhoto(log.getUser(), log.getImages().size());
        String key = storage.newKey(prefix(userId, id), req.contentType());
        return storage.presignUpload(key, req.contentType(), req.sizeBytes());
    }

    @Transactional
    public DiveLogResponseDto addImage(UUID id, Long userId, String key) {
        DiveLogModel log = findOwned(id, userId);

        // a key precisa pertencer a ESTE usuário e a ESTE mergulho
        if (!key.startsWith(prefix(userId, id))) {
            throw ApiException.badRequest("Imagem inválida para este mergulho");
        }
        if (log.getImages().stream().anyMatch(i -> i.getStorageKey().equals(key))) {
            return DiveLogResponseDto.from(log, storage);
        }

        planService.assertCanAddPhoto(log.getUser(), log.getImages().size());
        storage.assertUploaded(key);

        DiveLogImageModel image = new DiveLogImageModel();
        image.setDiveLog(log);
        image.setStorageKey(key);
        log.getImages().add(image);

        return DiveLogResponseDto.from(diveLogRepository.saveAndFlush(log), storage);
    }

    @Transactional
    public DiveLogResponseDto removeImage(UUID id, UUID imageId, Long userId) {
        DiveLogModel log = findOwned(id, userId);
        DiveLogImageModel image = log.getImages().stream()
                .filter(i -> i.getId().equals(imageId))
                .findFirst()
                .orElseThrow(() -> ApiException.notFound("Imagem não encontrada"));

        log.getImages().remove(image);
        DiveLogModel saved = diveLogRepository.saveAndFlush(log);
        storage.delete(image.getStorageKey());
        return DiveLogResponseDto.from(saved, storage);
    }

    // ---------------- util ----------------

    private DiveLogModel findOwned(UUID id, Long userId) {
        DiveLogModel log = diveLogRepository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Dive log não encontrado"));
        if (!log.getUser().getId().equals(userId)) {
            throw ApiException.notFound("Dive log não encontrado");
        }
        return log;
    }

    private DiveSiteModel activeSite(UUID siteId) {
        DiveSiteModel site = diveSiteRepository.findById(siteId)
                .orElseThrow(() -> ApiException.notFound("Dive site não encontrado"));
        if (!site.isAtivo()) {
            throw ApiException.badRequest("Este Dive Site está desativado");
        }
        return site;
    }

    private static void validateRules(CreateDiveLogDto dto) {
        if (dto.profundidadeMedia() != null && dto.profundidadeMaxima() != null
                && dto.profundidadeMedia() > dto.profundidadeMaxima()) {
            throw ApiException.badRequest("A profundidade média não pode ser maior que a máxima");
        }
        if (dto.pressaoInicial() != null && dto.pressaoFinal() != null
                && dto.pressaoFinal() > dto.pressaoInicial()) {
            throw ApiException.badRequest("A pressão final não pode ser maior que a inicial");
        }
        RatingRules.assertHalfStep(dto.notaExperiencia(), "A nota da experiência");
        RatingRules.assertHalfStep(dto.notaLocal(), "A nota do local");

        boolean temComentario = dto.comentarioLocal() != null && !dto.comentarioLocal().isBlank();
        if (temComentario && dto.notaLocal() == null) {
            throw ApiException.badRequest("Dê uma nota ao local para publicar o comentário");
        }
    }

    private static void apply(DiveLogModel log, CreateDiveLogDto dto) {
        log.setDataHora(dto.dataHora());
        log.setDuracaoMinutos(dto.duracaoMinutos());
        log.setProfundidadeMaxima(dto.profundidadeMaxima());
        log.setProfundidadeMedia(dto.profundidadeMedia());
        log.setVisibilidade(dto.visibilidade());
        log.setTemperaturaAgua(dto.temperaturaAgua());
        log.setCorrente(dto.corrente());
        log.setTipoAgua(dto.tipoAgua());
        log.setTipoEntrada(dto.tipoEntrada());
        log.setTipoGas(dto.tipoGas());
        log.setPressaoInicial(dto.pressaoInicial());
        log.setPressaoFinal(dto.pressaoFinal());
        log.setNotaExperiencia(dto.notaExperiencia());
        log.setNotaLocal(dto.notaLocal());
        log.setComentarioLocal(blankToNull(dto.comentarioLocal()));
        log.setObservacoes(blankToNull(dto.observacoes()));
    }

    private static String blankToNull(String v) {
        return v == null || v.isBlank() ? null : v.trim();
    }

    private static String prefix(Long userId, UUID logId) {
        return "dive-logs/" + userId + "/" + logId + "/";
    }
}
