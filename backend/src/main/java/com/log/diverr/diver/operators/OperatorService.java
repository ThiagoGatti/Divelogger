package com.log.diverr.diver.operators;

import com.log.diverr.diver.common.ApiException;
import com.log.diverr.diver.divesites.domain.DiveSiteModel;
import com.log.diverr.diver.divesites.repository.DiveSiteRepository;
import com.log.diverr.diver.operators.OperatorDtos.*;
import com.log.diverr.diver.storage.ImageStorageService;
import com.log.diverr.diver.storage.PresignRequestDto;
import com.log.diverr.diver.storage.PresignResponseDto;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/** Escrita é restrita a ADMIN no SecurityConfig. Leitura: qualquer usuário autenticado (só operadoras ativas). */
@Service
public class OperatorService {

    private final OperatorRepository repository;
    private final DiveSiteRepository siteRepository;
    private final ImageStorageService storage;

    public OperatorService(
            OperatorRepository repository,
            DiveSiteRepository siteRepository,
            ImageStorageService storage
    ) {
        this.repository = repository;
        this.siteRepository = siteRepository;
        this.storage = storage;
    }

    @Transactional(readOnly = true)
    public List<OperatorSummaryDto> list(boolean includeInactive, boolean isAdmin) {
        List<OperatorModel> list = (includeInactive && isAdmin)
                ? repository.findAllByOrderByNomeAsc()
                : repository.findByAtivoTrueOrderByNomeAsc();
        return list.stream().map(o -> OperatorSummaryDto.from(o, storage)).toList();
    }

    @Transactional(readOnly = true)
    public OperatorDetailDto get(UUID id, boolean isAdmin) {
        OperatorModel o = find(id);
        if (!o.isAtivo() && !isAdmin) {
            throw ApiException.notFound("Operadora não encontrada");
        }
        return detail(o, isAdmin);
    }

    @Transactional
    public OperatorDetailDto create(OperatorRequestDto dto) {
        OperatorModel o = new OperatorModel();
        apply(o, dto);
        return detail(repository.saveAndFlush(o), true);
    }

    @Transactional
    public OperatorDetailDto update(UUID id, OperatorRequestDto dto) {
        OperatorModel o = find(id);
        apply(o, dto);
        return detail(repository.saveAndFlush(o), true);
    }

    @Transactional
    public OperatorDetailDto setAtivo(UUID id, boolean ativo) {
        OperatorModel o = find(id);
        o.setAtivo(ativo);
        o.setUpdatedAt(LocalDateTime.now());
        return detail(repository.saveAndFlush(o), true);
    }

    /** Define em quais Dive Sites a operadora atua (substitui os vínculos atuais). */
    @Transactional
    public OperatorDetailDto setSites(UUID id, List<UUID> siteIds) {
        OperatorModel o = find(id);
        Set<UUID> wanted = new HashSet<>(siteIds);

        // remove vínculos que saíram
        for (DiveSiteModel s : new HashSet<>(o.getSites())) {
            if (!wanted.contains(s.getId())) {
                s.getOperators().remove(o);
                o.getSites().remove(s);
            }
        }
        // adiciona os novos
        Set<UUID> current = o.getSites().stream().map(DiveSiteModel::getId).collect(Collectors.toSet());
        for (UUID siteId : wanted) {
            if (current.contains(siteId)) continue;
            DiveSiteModel s = siteRepository.findById(siteId)
                    .orElseThrow(() -> ApiException.notFound("Dive site não encontrado"));
            s.getOperators().add(o);
            o.getSites().add(s);
        }
        siteRepository.flush();
        return detail(o, true);
    }

    // ---------------- foto ----------------

    @Transactional(readOnly = true)
    public PresignResponseDto presignPhoto(UUID id, PresignRequestDto req) {
        find(id);
        String key = storage.newKey("operators/" + id + "/", req.contentType());
        return storage.presignUpload(key, req.contentType(), req.sizeBytes());
    }

    @Transactional
    public OperatorDetailDto setPhoto(UUID id, String key) {
        OperatorModel o = find(id);
        if (!key.startsWith("operators/" + id + "/")) {
            throw ApiException.badRequest("Imagem inválida para esta operadora");
        }
        storage.assertUploaded(key);

        String old = o.getPhotoKey();
        o.setPhotoKey(key);
        o.setUpdatedAt(LocalDateTime.now());
        repository.saveAndFlush(o);
        if (old != null && !old.equals(key)) {
            storage.delete(old);
        }
        return detail(o, true);
    }

    @Transactional
    public OperatorDetailDto removePhoto(UUID id) {
        OperatorModel o = find(id);
        String old = o.getPhotoKey();
        o.setPhotoKey(null);
        o.setUpdatedAt(LocalDateTime.now());
        repository.saveAndFlush(o);
        storage.delete(old);
        return detail(o, true);
    }

    // ---------------- util ----------------

    private OperatorModel find(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Operadora não encontrada"));
    }

    private static void apply(OperatorModel o, OperatorRequestDto dto) {
        o.setNome(dto.nome().trim());
        o.setEndereco(dto.endereco() == null || dto.endereco().isBlank() ? null : dto.endereco().trim());
        o.setUpdatedAt(LocalDateTime.now());
    }

    private OperatorDetailDto detail(OperatorModel o, boolean isAdmin) {
        OperatorSummaryDto s = OperatorSummaryDto.from(o, storage);
        List<SiteRefDto> sites = o.getSites().stream()
                .filter(site -> isAdmin || site.isAtivo())
                .sorted((a, b) -> a.getNome().compareToIgnoreCase(b.getNome()))
                .map(site -> new SiteRefDto(
                        site.getId(),
                        site.getNome(),
                        Stream.of(site.getCidade(), site.getEstado(), site.getPais())
                                .filter(v -> v != null && !v.isBlank())
                                .collect(Collectors.joining(", ")),
                        site.isAtivo()))
                .toList();
        return new OperatorDetailDto(s.id(), s.nome(), s.endereco(), s.photoUrl(), s.photoId(), s.ativo(), sites);
    }
}
