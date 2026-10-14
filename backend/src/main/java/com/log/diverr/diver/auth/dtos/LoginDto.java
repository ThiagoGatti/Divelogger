package com.log.diverr.diver.auth.dtos;

import jakarta.validation.constraints.NotBlank;

public record LoginDto(
        @NotBlank(message = "E-mail é obrigatório") String email,
        @NotBlank(message = "Senha é obrigatória") String senha
) {}
