package com.log.diverr.diver.reviews;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public final class ReviewDtos {

    private ReviewDtos() {}

    public record ReviewRequestDto(
            @NotNull(message = "Informe a nota de 1 a 5")
            @Min(value = 1, message = "A nota deve ser de 1 a 5")
            @Max(value = 5, message = "A nota deve ser de 1 a 5")
            Integer rating,

            @Size(max = 2000, message = "O comentário deve ter no máximo 2000 caracteres")
            String texto
    ) {}

    public record ReviewDto(
            UUID id,
            Long userId,
            String autor,
            String username,
            int rating,
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
