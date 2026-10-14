package com.log.diverr.diver.users.dtos;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record CreateUserDto(
        @NotBlank(message = "Nome é obrigatório")
        @Size(max = 150, message = "Nome muito longo")
        String nomeCompleto,
        @NotBlank(message = "E-mail é obrigatório")
        @Email(message = "E-mail inválido")
        String email,
        String telefone,
        @NotBlank(message = "Senha é obrigatória")
        @Size(min = 8, max = 72, message = "A senha deve ter entre 8 e 72 caracteres")
        String senha,
        String documento,
        LocalDate dataNascimento,
        boolean aceitouTermosUso,
        boolean aceitouPoliticaPrivacidade
) {}