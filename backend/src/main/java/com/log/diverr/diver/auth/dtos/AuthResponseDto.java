package com.log.diverr.diver.auth.dtos;

import com.log.diverr.diver.users.dtos.UserResponseDto;

public record AuthResponseDto(
        String accessToken,
        String tokenType,
        long expiresIn,
        UserResponseDto user
) {
}