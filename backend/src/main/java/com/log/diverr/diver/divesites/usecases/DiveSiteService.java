package com.log.diverr.diver.divesites.usecases;

import com.log.diverr.diver.common.ApiException;
import com.log.diverr.diver.divesites.domain.DiveSiteImageModel;
import com.log.diverr.diver.divesites.domain.DiveSiteModel;
import com.log.diverr.diver.divesites.dtos.CreateDiveSiteDto;
import com.log.diverr.diver.divesites.dtos.DiveSiteResponseDto;
import com.log.diverr.diver.divesites.repository.DiveSiteRepository;
import com.log.diverr.diver.plans.PlanService;
import com.log.diverr.diver.reviews.DiveSiteReviewRepository;
import com.log.diverr.diver.reviews.DiveSiteReviewService;
import com.log.diverr.diver.storage.ImageStorageService;
import com.log.diverr.diver.storage.PresignRequestDto;
import com.log.diverr.diver.storage.PresignResponseDto;
import com.log.diverr.diver.users.domain.UserModel;
import com.log.diverr.diver.users.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Regras de Dive Sites. Escrita é restrita a ADMIN no SecurityConfig; aqui ficam as regras de dados. */
@Service
public class DiveSiteService {

    private static final int MAX_IMAGES_PER_SITE = 10;

    private final DiveSiteRepository repository;
    private final UserRepository userRepository;
    private final ImageStorageService storage;
    private final PlanService planService;
    private final DiveSiteReviewRepository reviewRepository;

    public DiveSiteService(
            DiveSiteRepository repository,
            UserRepository userRepository,
            ImageStorageService storage,
            PlanService planService,
            DiveSiteReviewRepository reviewRepository
    ) {
        this.repository = repository;
        this.userRepository = userRepository;
        this.storage = storage;
        this.planService = planService;
        this.reviewRepository = reviewRepository;
    }

    /** Usuário comum só vê locais ativos. ADMIN pode pedir também os inativos. */
    @Transactional(readOnly = true)
    public List<DiveSiteResponseDto> list(boolean includeInactive, boolean isAdmin, Long userId) {
        List<DiveSiteModel> sites = (includeInactive && isAdmin)
                ? repository.findAllByOrderByNomeAsc()
                : repository.findByAtivoTrueOrderByNomeAsc();

        DiveSiteResponseDto.Access access = accessFor(userId, isAdmin);

        Map<UUID, DiveSiteReviewRepository.RatingRow> ratings = new HashMap<>();
        reviewRepository.aggregateAll().forEach(r -> ratings.put(r.getSiteId(), r));

        return sites.stream().map(s -> {
            var r = ratings.get(s.getId());
            return DiveSiteResponseDto.from(
                    s, storage, access,
                    r == null ? null : DiveSiteReviewService.round1(r.getAverage()),
                    r == null || r.getTotal() == null ? 0L : r.getTotal());
        }).toList();
    }

    @Transactional(readOnly = true)
    public DiveSiteResponseDto get(UUID id, boolean isAdmin, Long userId) {
        DiveSiteModel site = find(id);
        if (!site.isAtivo() && !isAdmin) {
            throw ApiException.notFound("Dive site não encontrado");
        }
        return toDto(site, accessFor(userId, isAdmin));
    }

    @Transactional
    public DiveSiteResponseDto create(CreateDiveSiteDto dto, Long userId) {
        UserModel user = userRepository.findById(userId)
                .orElseThrow(() -> ApiException.unauthorized("Usuário não encontrado"));

        DiveSiteModel site = new DiveSiteModel();
        apply(site, dto);
        site.setCreatedBy(user);
        return toDto(repository.save(site), DiveSiteResponseDto.Access.admin());
    }

    @Transactional
    public DiveSiteResponseDto update(UUID id, CreateDiveSiteDto dto) {
        DiveSiteModel site = find(id);
        apply(site, dto);
        return toDto(repository.save(site), DiveSiteResponseDto.Access.admin());
    }

    @Transactional
    public DiveSiteResponseDto setAtivo(UUID id, boolean ativo) {
        DiveSiteModel site = find(id);
        site.setAtivo(ativo);
        site.setUpdatedAt(LocalDateTime.now());
        return toDto(repository.save(site), DiveSiteResponseDto.Access.admin());
    }

    // ---------------- imagens (ADMIN) ----------------

    @Transactional(readOnly = true)
    public PresignResponseDto presignImage(UUID id, PresignRequestDto req) {
        DiveSiteModel site = find(id);
        if (site.getImages().size() >= MAX_IMAGES_PER_SITE) {
            throw ApiException.badRequest("Limite de " + MAX_IMAGES_PER_SITE + " fotos por Dive Site");
        }
        String key = storage.newKey(prefix(id), req.contentType());
        return storage.presignUpload(key, req.contentType(), req.sizeBytes());
    }

    @Transactional
    public DiveSiteResponseDto addImage(UUID id, String key) {
        DiveSiteModel site = find(id);

        if (!key.startsWith(prefix(id))) {
            throw ApiException.badRequest("Imagem inválida para este Dive Site");
        }
        if (site.getImages().size() >= MAX_IMAGES_PER_SITE) {
            throw ApiException.badRequest("Limite de " + MAX_IMAGES_PER_SITE + " fotos por Dive Site");
        }
        if (site.getImages().stream().anyMatch(i -> i.getStorageKey().equals(key))) {
            return toDto(site, DiveSiteResponseDto.Access.admin());
        }

        storage.assertUploaded(key);

        DiveSiteImageModel image = new DiveSiteImageModel();
        image.setDiveSite(site);
        image.setStorageKey(key);
        site.getImages().add(image);

        return toDto(repository.saveAndFlush(site), DiveSiteResponseDto.Access.admin());
    }

    @Transactional
    public DiveSiteResponseDto removeImage(UUID id, UUID imageId) {
        DiveSiteModel site = find(id);
        DiveSiteImageModel image = site.getImages().stream()
                .filter(i -> i.getId().equals(imageId))
                .findFirst()
                .orElseThrow(() -> ApiException.notFound("Imagem não encontrada"));

        site.getImages().remove(image);
        DiveSiteModel saved = repository.saveAndFlush(site);
        storage.delete(image.getStorageKey());
        return toDto(saved, DiveSiteResponseDto.Access.admin());
    }

    // ---------------- util ----------------

    private DiveSiteResponseDto.Access accessFor(Long userId, boolean isAdmin) {
        if (isAdmin) {
            return DiveSiteResponseDto.Access.admin();
        }
        UserModel user = userRepository.findById(userId)
                .orElseThrow(() -> ApiException.unauthorized("Usuário não encontrado"));
        return new DiveSiteResponseDto.Access(
                planService.canSeeExtendedSiteInfo(user),
                planService.maxSitePhotosVisible(user));
    }

    private DiveSiteResponseDto toDto(DiveSiteModel site, DiveSiteResponseDto.Access access) {
        var rating = reviewRepository.aggregateFor(site.getId());
        return DiveSiteResponseDto.from(
                site, storage, access,
                rating.map(r -> DiveSiteReviewService.round1(r.getAverage())).orElse(null),
                rating.map(r -> r.getTotal() == null ? 0L : r.getTotal()).orElse(0L));
    }

    private DiveSiteModel find(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Dive site não encontrado"));
    }

    private static String prefix(UUID siteId) {
        return "dive-sites/" + siteId + "/";
    }

    private static void apply(DiveSiteModel site, CreateDiveSiteDto dto) {
        site.setNome(dto.nome().trim());
        site.setDescricao(blankToNull(dto.descricao()));
        site.setPais(dto.pais().trim());
        site.setEstado(blankToNull(dto.estado()));
        site.setCidade(blankToNull(dto.cidade()));
        site.setLatitude(dto.latitude());
        site.setLongitude(dto.longitude());
        site.setProfundidadeMaxima(dto.profundidadeMaxima());
        site.setTipo(dto.tipo());
        site.setNivel(dto.nivel());
        site.setMelhorEpoca(blankToNull(dto.melhorEpoca()));
        site.setVisibilidadeTipica(blankToNull(dto.visibilidadeTipica()));
        site.setTemperaturaAgua(blankToNull(dto.temperaturaAgua()));
        site.setCorrenteTipica(blankToNull(dto.correnteTipica()));
        site.setCertificacaoMinima(blankToNull(dto.certificacaoMinima()));
        site.setFaunaFlora(blankToNull(dto.faunaFlora()));
        site.setComoChegar(blankToNull(dto.comoChegar()));
        site.setInfraestrutura(blankToNull(dto.infraestrutura()));
        site.setDicas(blankToNull(dto.dicas()));
        site.setAvisosSeguranca(blankToNull(dto.avisosSeguranca()));
        site.setUpdatedAt(LocalDateTime.now());
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
