package com.log.diverr.diver.divelogs.dtos;

import com.log.diverr.diver.divelogs.domain.DiveLogModel;

import java.time.LocalDateTime;
import java.util.UUID;

public record DiveLogResponseDto(
        UUID id,

        Long userId,
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

        Integer avaliacao,

        String observacoes
) {

    public static DiveLogResponseDto from(DiveLogModel diveLog) {

        return new DiveLogResponseDto(
                diveLog.getId(),

                diveLog.getUser().getId(),
                diveLog.getDiveSite().getId(),
                diveLog.getDiveSite().getNome(),

                diveLog.getDataHora(),

                diveLog.getDuracaoMinutos(),

                diveLog.getProfundidadeMaxima(),
                diveLog.getProfundidadeMedia(),

                diveLog.getVisibilidade(),
                diveLog.getTemperaturaAgua(),

                diveLog.getCorrente(),
                diveLog.getTipoAgua(),
                diveLog.getTipoEntrada(),
                diveLog.getTipoGas(),

                diveLog.getPressaoInicial(),
                diveLog.getPressaoFinal(),

                diveLog.getAvaliacao(),

                diveLog.getObservacoes()
        );
    }
}