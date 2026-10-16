package com.log.diverr.diver.divelogs.usecases;

import com.log.diverr.diver.common.ApiException;
import com.log.diverr.diver.divelogs.domain.DiveLogImageModel;
import com.log.diverr.diver.divelogs.domain.DiveLogModel;
import com.log.diverr.diver.divelogs.dtos.CreateDiveLogDto;
import com.log.diverr.diver.divelogs.dtos.DiveLogResponseDto;
import com.log.diverr.diver.divelogs.repository.DiveLogRepository;
import com.log.diverr.diver.divesites.domain.DiveSiteModel;
import com.log.diverr.diver.divesites.repository.DiveSiteRepository;
import com.log.diverr.diver.plans.PlanService;
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
 * CRUD dos mergulhos. Todo acesso é filtrado pelo usuário autenticado (userId do token).
 * Mergulho de outra pessoa responde 404 (não revela que existe).
 */
@Service
public class DiveLogService {

    private final DiveLogRepository diveLogRepository;
    private final UserRepository userRepository;
    private final DiveSiteRepository diveSiteRepository;
    private final PlanService planService;
    private final ImageStorageService storage;

    public DiveLogService(
            DiveLogRepository diveLogRepository,
            UserRepository userRepository,
            DiveSiteRepository diveSiteRepository,
            PlanService planService,
            ImageStorageService storage
    ) {
        this.diveLogRepository = diveLogRepository;
        this.userRepository = userRepository;
        this.diveSiteRepository = diveSiteRepository;
        this.planService = planService;
        this.storage = storage;
    }

    @Transactional(readOnly = true)
    public List<DiveLogResponseDto> listMine(Long userId) {
        return diveLogRepository.findByUserIdOrderByDataHoraDesc(userId).stream()
                .map(l -> DiveLogResponseDto.from(l, storage)).toList();
    }

    @Transactional(readOnly = true)
    public List<DiveLogResponseDto> listMineBySite(UUID siteId, Long userId) {
        return diveLogRepository.findByDiveSiteIdAndUserIdOrderByDataHoraDesc(siteId, userId).stream()
                .map(l -> DiveLogResponseDto.from(l, storage)).toList();
    }

    @Transactional(readOnly = true)
    public DiveLogResponseDto get(UUID id, Long userId, boolean isAdmin) {
        return DiveLogResponseDto.from(findOwned(id, userId, isAdmin), storage);
    }

    @Transactional
    public DiveLogResponseDto create(CreateDiveLogDto dto, Long userId) {
        UserModel user = userRepository.findById(userId)
                .orElseThrow(() -> ApiException.unauthorized("Usuário não encontrado"));

        DiveSiteModel site = activeSite(dto.diveSiteId());
        validateRules(dto);

        DiveLogModel log = new DiveLogModel();
        log.setUser(user);
        log.setDiveSite(site);
        apply(log, dto);

        return DiveLogResponseDto.from(diveLogRepository.saveAndFlush(log), storage);
    }

    @Transactional
    public DiveLogResponseDto update(UUID id, CreateDiveLogDto dto, Long userId) {
        DiveLogModel log = findOwned(id, userId, false);
        validateRules(dto);

        // só exige site ativo se o mergulho mudou de local (mergulhos antigos em locais desativados continuam editáveis)
        if (!log.getDiveSite().getId().equals(dto.diveSiteId())) {
            log.setDiveSite(activeSite(dto.diveSiteId()));
        }
        apply(log, dto);

        return DiveLogResponseDto.from(diveLogRepository.saveAndFlush(log), storage);
    }

    @Transactional
    public void delete(UUID id, Long userId) {
        DiveLogModel log = findOwned(id, userId, false);
        List<String> keys = log.getImages().stream().map(DiveLogImageModel::getStorageKey).toList();
        diveLogRepository.delete(log);
        diveLogRepository.flush();
        keys.forEach(storage::delete);
    }

    // ---------------- imagens ----------------

    @Transactional(readOnly = true)
    public PresignResponseDto presignImage(UUID id, Long userId, PresignRequestDto req) {
        DiveLogModel log = findOwned(id, userId, false);
        planService.assertCanAddPhoto(log.getUser(), log.getImages().size());
        String key = storage.newKey(prefix(userId, id), req.contentType());
        return storage.presignUpload(key, req.contentType(), req.sizeBytes());
    }

    @Transactional
    public DiveLogResponseDto addImage(UUID id, Long userId, String key) {
        DiveLogModel log = findOwned(id, userId, false);

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
        DiveLogModel log = findOwned(id, userId, false);
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

    private DiveLogModel findOwned(UUID id, Long userId, boolean isAdmin) {
        DiveLogModel log = diveLogRepository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Dive log não encontrado"));
        if (!isAdmin && !log.getUser().getId().equals(userId)) {
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
        log.setAvaliacao(dto.avaliacao());
        log.setObservacoes(dto.observacoes() == null || dto.observacoes().isBlank() ? null : dto.observacoes().trim());
    }

    private static String prefix(Long userId, UUID logId) {
        return "dive-logs/" + userId + "/" + logId + "/";
    }
}
