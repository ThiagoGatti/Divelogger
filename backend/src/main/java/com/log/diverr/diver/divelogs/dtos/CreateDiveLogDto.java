package com.log.diverr.diver.divelogs.dtos;

import com.log.diverr.diver.divelogs.domain.DiveLogModel;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;
import java.util.UUID;

/** Criar e editar (PUT) um mergulho. O dono NUNCA vem daqui: é sempre o usuário do token. */
public record CreateDiveLogDto(
        @NotNull(message = "Selecione o Dive Site")
        UUID diveSiteId,

        @NotNull(message = "Informe a data e a hora do mergulho")
        LocalDateTime dataHora,

        @Min(value = 1, message = "Duração deve ser de pelo menos 1 minuto")
        @Max(value = 1440, message = "Duração inválida")
        Integer duracaoMinutos,

        @DecimalMin(value = "0.0", message = "Profundidade máxima inválida")
        @DecimalMax(value = "400.0", message = "Profundidade máxima inválida")
        Double profundidadeMaxima,

        @DecimalMin(value = "0.0", message = "Profundidade média inválida")
        @DecimalMax(value = "400.0", message = "Profundidade média inválida")
        Double profundidadeMedia,

        @DecimalMin(value = "0.0", message = "Visibilidade inválida")
        @DecimalMax(value = "200.0", message = "Visibilidade inválida")
        Double visibilidade,

        @DecimalMin(value = "-5.0", message = "Temperatura inválida")
        @DecimalMax(value = "50.0", message = "Temperatura inválida")
        Double temperaturaAgua,

        DiveLogModel.TipoCorrente corrente,
        DiveLogModel.TipoAgua tipoAgua,
        DiveLogModel.TipoEntrada tipoEntrada,
        DiveLogModel.TipoGas tipoGas,

        @Min(value = 0, message = "Pressão inicial inválida")
        @Max(value = 400, message = "Pressão inicial inválida")
        Integer pressaoInicial,

        @Min(value = 0, message = "Pressão final inválida")
        @Max(value = 400, message = "Pressão final inválida")
        Integer pressaoFinal,

        /** "Minha experiência": 0,5 a 5 (meia estrela). */
        @DecimalMin(value = "0.5", message = "A nota da experiência deve ir de 0,5 a 5")
        @DecimalMax(value = "5.0", message = "A nota da experiência deve ir de 0,5 a 5")
        Double notaExperiencia,

        /** "Local do mergulho": vira também a avaliação do Dive Site. */
        @DecimalMin(value = "0.5", message = "A nota do local deve ir de 0,5 a 5")
        @DecimalMax(value = "5.0", message = "A nota do local deve ir de 0,5 a 5")
        Double notaLocal,

        @Size(max = 2000, message = "O comentário do local deve ter no máximo 2000 caracteres")
        String comentarioLocal,

        @Size(max = 3000, message = "Observações muito longas (máx. 3000)")
        String observacoes,

        /** Opcional. Gerado pelo app ao criar offline; torna o envio idempotente. */
        UUID clientId
) {
}
