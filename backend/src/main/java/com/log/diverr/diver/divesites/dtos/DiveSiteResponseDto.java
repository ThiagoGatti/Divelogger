package com.log.diverr.diver.divesites.dtos;

import com.log.diverr.diver.divesites.domain.DiveSiteModel;

import java.math.BigDecimal;
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
        DiveSiteModel.TipoDiveSite tipo
) {

    public static DiveSiteResponseDto from(DiveSiteModel diveSite) {
        return new DiveSiteResponseDto(
                diveSite.getId(),
                diveSite.getNome(),
                diveSite.getDescricao(),
                diveSite.getPais(),
                diveSite.getEstado(),
                diveSite.getCidade(),
                diveSite.getLatitude(),
                diveSite.getLongitude(),
                diveSite.getProfundidadeMaxima(),
                diveSite.getTipo()
        );
    }
}