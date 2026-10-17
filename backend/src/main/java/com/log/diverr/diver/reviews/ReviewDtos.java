package com.log.diverr.diver.reviews;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public final class ReviewDtos {

    private ReviewDtos() {}

    public record ReviewRequestDto(
            @NotNull(message = "Informe a nota")
            @DecimalMin(value = "0.5", message = "A nota deve ir de 0,5 a 5")
            @DecimalMax(value = "5.0", message = "A nota deve ir de 0,5 a 5")
            Double rating,

            @Size(max = 2000, message = "O comentário deve ter no máximo 2000 caracteres")
            String texto
    ) {}

    public record ReviewDto(
            UUID id,
            Long userId,
            String autor,
            String username,
            double rating,
            String texto,
            LocalDateTime createdAt,
            boolean mine
    ) {}

    public record ReviewsResponseDto(
            Double average,
            long count,
            ReviewDto mine,
            List<ReviewDto> items
    ) {}
}
