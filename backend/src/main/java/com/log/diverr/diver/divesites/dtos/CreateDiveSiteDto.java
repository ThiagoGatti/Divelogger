package com.log.diverr.diver.divesites.dtos;

import com.log.diverr.diver.divesites.domain.DiveSiteModel;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

/** Usado para criar e para editar (PUT) um Dive Site. Apenas ADMIN. */
public record CreateDiveSiteDto(
        @NotBlank(message = "Nome é obrigatório")
        @Size(max = 150, message = "Nome muito longo")
        String nome,

        @Size(max = 1000, message = "Descrição muito longa (máx. 1000)")
        String descricao,

        @NotBlank(message = "País é obrigatório")
        String pais,

        String estado,
        String cidade,

        @NotNull(message = "Latitude é obrigatória")
        @DecimalMin(value = "-90", message = "Latitude inválida")
        @DecimalMax(value = "90", message = "Latitude inválida")
        BigDecimal latitude,

        @NotNull(message = "Longitude é obrigatória")
        @DecimalMin(value = "-180", message = "Longitude inválida")
        @DecimalMax(value = "180", message = "Longitude inválida")
        BigDecimal longitude,

        @PositiveOrZero(message = "Profundidade inválida")
        Double profundidadeMaxima,

        DiveSiteModel.TipoDiveSite tipo
) {
}
