package com.log.diverr.diver.auth.dtos;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record ResetPasswordDto(
        @NotBlank(message = "E-mail é obrigatório")
        String email,

        @NotBlank(message = "Informe o código")
        @Pattern(regexp = "\\d{6}", message = "O código tem 6 dígitos")
        String code,

        @NotBlank(message = "Informe a nova senha")
        @Size(min = 8, max = 72, message = "A senha deve ter entre 8 e 72 caracteres")
        String newPassword
) {}
