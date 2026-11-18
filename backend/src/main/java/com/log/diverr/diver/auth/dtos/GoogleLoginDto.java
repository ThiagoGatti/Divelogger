package com.log.diverr.diver.auth.dtos;

import jakarta.validation.constraints.NotBlank;

/** idToken: o ID token que o app recebe do Google. acceptedTerms: o usuário aceitou Termos e Política (necessário só para contas novas). */
public record GoogleLoginDto(
        @NotBlank(message = "Token do Google é obrigatório") String idToken,
        Boolean acceptedTerms
) {}
