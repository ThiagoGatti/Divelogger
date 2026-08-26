package com.log.diverr.diver.divelogs.dtos;

import java.time.LocalDateTime;
import java.util.UUID;

import com.log.diverr.diver.divelogs.domain.DiveLogModel;

public record CreateDiveLogDto(
        Long userId,
        UUID diveSiteId,

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

        Integer avaliacao,

        String observacoes
) {
}