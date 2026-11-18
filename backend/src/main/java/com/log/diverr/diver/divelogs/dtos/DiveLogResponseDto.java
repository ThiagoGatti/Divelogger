package com.log.diverr.diver.divelogs.dtos;

import com.log.diverr.diver.divelogs.domain.DiveLogModel;
import com.log.diverr.diver.storage.ImageDto;
import com.log.diverr.diver.storage.ImageStorageService;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public record DiveLogResponseDto(
        UUID id,
        Long userId,
        String ownerNome,
        String ownerUsername,
        String ownerPhotoUrl,
        String ownerPhotoId,
        UUID diveSiteId,
        String diveSiteNome,
        LocalDateTime dataHora,
        Integer duracaoMinutos,
        Double profundidadeMaxima,
        Double profundidadeMedia,
        Double visibilidade,
        Double temperaturaAgua,
        DiveLogModel.TipoCorrente corrente,
        DiveLogModel.TipoAgua tipoAgua,
        DiveLogModel.TipoEntrada tipoEntrada,
        DiveLogModel.TipoGas tipoGas,
        Integer pressaoInicial,
        Integer pressaoFinal,
        Double notaExperiencia,
        Double notaLocal,
        String comentarioLocal,
        String observacoes,
        LocalDateTime updatedAt,
        List<ImageDto> imagens
) {
    public static DiveLogResponseDto from(DiveLogModel log, ImageStorageService storage) {
        return new DiveLogResponseDto(
                log.getId(),
                log.getUser().getId(),
                log.getUser().getNomeCompleto(),
                log.getUser().getUsername(),
                com.log.diverr.diver.storage.PhotoUrls.url(log.getUser()),
                com.log.diverr.diver.storage.PhotoUrls.id(log.getUser()),
                log.getDiveSite().getId(),
                log.getDiveSite().getNome(),
                log.getDataHora(),
                log.getDuracaoMinutos(),
                log.getProfundidadeMaxima(),
                log.getProfundidadeMedia(),
                log.getVisibilidade(),
                log.getTemperaturaAgua(),
                log.getCorrente(),
                log.getTipoAgua(),
                log.getTipoEntrada(),
                log.getTipoGas(),
                log.getPressaoInicial(),
                log.getPressaoFinal(),
                log.getNotaExperiencia(),
                log.getNotaLocal(),
                log.getComentarioLocal(),
                log.getObservacoes(),
                log.getUpdatedAt(),
                log.getImages().stream()
                        .map(i -> new ImageDto(i.getId(), storage.urlFor(i.getStorageKey())))
                        .toList()
        );
    }
}
