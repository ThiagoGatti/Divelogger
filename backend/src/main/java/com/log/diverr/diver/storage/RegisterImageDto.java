package com.log.diverr.diver.storage;

import jakarta.validation.constraints.NotBlank;

public record RegisterImageDto(@NotBlank(message = "Informe a chave da imagem") String key) {
}
