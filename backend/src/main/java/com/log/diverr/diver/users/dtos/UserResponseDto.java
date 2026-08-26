package com.log.diverr.diver.users.dtos;

import com.log.diverr.diver.users.domain.UserModel;

import java.time.LocalDate;

public record UserResponseDto(
        Long id,
        String nomeCompleto,
        String email,
        String telefone,
        LocalDate dataNascimento,
        boolean verificado,
        UserModel.Plano plano
) {
    public static UserResponseDto from(UserModel user) {
        return new UserResponseDto(
                user.getId(),
                user.getNomeCompleto(),
                user.getEmail(),
                user.getTelefone(),
                user.getDataNascimento(),
                user.isVerificado(),
                user.getPlano()
        );
    }
}