package com.log.diverr.diver.divesites.dtos;

import com.log.diverr.diver.divesites.domain.DiveSiteImageModel;
import com.log.diverr.diver.divesites.domain.DiveSiteModel;
import com.log.diverr.diver.storage.ImageDto;
import com.log.diverr.diver.storage.ImageStorageService;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record DiveSiteResponseDto(
        UUID id,
        String nome,
        String descricao,
        String pais,
        String estado,
        String cidade,
        BigDecimal latitude,
        BigDecimal longitude,
        Double profundidadeMaxima,
        DiveSiteModel.TipoDiveSite tipo,
        boolean ativo,
        List<ImageDto> images
) {
    public static DiveSiteResponseDto from(DiveSiteModel site, ImageStorageService storage) {
        return new DiveSiteResponseDto(
                site.getId(),
                site.getNome(),
                site.getDescricao(),
                site.getPais(),
                site.getEstado(),
                site.getCidade(),
                site.getLatitude(),
                site.getLongitude(),
                site.getProfundidadeMaxima(),
                site.getTipo(),
                site.isAtivo(),
                site.getImages().stream()
                        .map((DiveSiteImageModel i) -> new ImageDto(i.getId(), storage.urlFor(i.getStorageKey())))
                        .toList()
        );
    }
}
