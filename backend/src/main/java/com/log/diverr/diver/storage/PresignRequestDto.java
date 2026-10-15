package com.log.diverr.diver.storage;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record PresignRequestDto(
        @NotBlank(message = "Informe o tipo da imagem") String contentType,
        @NotNull(message = "Informe o tamanho da imagem") @Positive(message = "Tamanho inválido") Long sizeBytes
) {
}
