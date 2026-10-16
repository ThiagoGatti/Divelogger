package com.log.diverr.diver.divesites.dtos;

import com.log.diverr.diver.divesites.domain.DiveSiteModel;

/** Informações avançadas do local. Só é enviada para Premium e ADMIN. */
public record DiveSiteExtendedDto(
        String melhorEpoca,
        String visibilidadeTipica,
        String temperaturaAgua,
        String correnteTipica,
        String certificacaoMinima,
        String faunaFlora,
        String comoChegar,
        String infraestrutura,
        String dicas,
        String avisosSeguranca
) {
    public static DiveSiteExtendedDto from(DiveSiteModel s) {
        return new DiveSiteExtendedDto(
                s.getMelhorEpoca(),
                s.getVisibilidadeTipica(),
                s.getTemperaturaAgua(),
                s.getCorrenteTipica(),
                s.getCertificacaoMinima(),
                s.getFaunaFlora(),
                s.getComoChegar(),
                s.getInfraestrutura(),
                s.getDicas(),
                s.getAvisosSeguranca()
        );
    }
}
