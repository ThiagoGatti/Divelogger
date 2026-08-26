package com.log.diverr.diver.divesites.dtos;

import com.log.diverr.diver.divesites.domain.DiveSiteModel;

import java.math.BigDecimal;

public record CreateDiveSiteDto(
        String nome,
        String descricao,
        String pais,
        String estado,
        String cidade,
        BigDecimal latitude,
        BigDecimal longitude,
        Double profundidadeMaxima,
        DiveSiteModel.TipoDiveSite tipo,
        Long createdBy
) {
}