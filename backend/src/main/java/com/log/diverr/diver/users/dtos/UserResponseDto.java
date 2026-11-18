package com.log.diverr.diver.users.dtos;

import com.log.diverr.diver.users.domain.DiveVisibility;
import com.log.diverr.diver.users.domain.Role;
import com.log.diverr.diver.users.domain.UserModel;

import java.time.LocalDate;

public record UserResponseDto(
        Long id,
        String nomeCompleto,
        String email,
        String telefone,
        LocalDate dataNascimento,
        boolean verificado,
        UserModel.Plano plano,
        Role role,
        LocalDate planExpiresAt,
        String username,
        String bio,
        DiveVisibility diveVisibility,
        String photoUrl,
        String photoId
) {
    public static UserResponseDto from(UserModel user) {
        return new UserResponseDto(
                user.getId(),
                user.getNomeCompleto(),
                user.getEmail(),
                user.getTelefone(),
                user.getDataNascimento(),
                user.isVerificado(),
                user.getPlano(),
                user.getRole(),
                user.getPlanExpiresAt(),
                user.getUsername(),
                user.getBio(),
                user.getDiveVisibility(),
                com.log.diverr.diver.storage.PhotoUrls.url(user),
                com.log.diverr.diver.storage.PhotoUrls.id(user)
        );
    }
}