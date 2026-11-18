package com.log.diverr.diver.social;

import com.log.diverr.diver.divelogs.dtos.DiveLogResponseDto;
import com.log.diverr.diver.users.domain.DiveVisibility;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public final class SocialDtos {

    private SocialDtos() {}

    public record UserSummaryDto(
            Long id,
            String nome,
            String username,
            String photoUrl,
            String photoId,
            boolean iFollow,
            boolean followsMe,
            boolean friends
    ) {}

    public record PublicProfileDto(
            Long id,
            String nomeCompleto,
            String username,
            String bio,
            String photoUrl,
            String photoId,
            boolean self,
            long followers,
            long following,
            long friends,
            boolean iFollow,
            boolean followsMe,
            boolean isFriend,
            DiveVisibility diveVisibility,
            boolean canViewDives,
            Long divesCount,
            Integer sitesCount
    ) {}

    public record SocialSummaryDto(
            Map<String, Long> reactions,
            String myReaction,
            long commentsCount
    ) {}

    public record ReactionRequestDto(
            @NotBlank(message = "Escolha uma reação") String emoji
    ) {}

    public record CommentRequestDto(
            @NotBlank(message = "Escreva um comentário")
            @Size(max = 1000, message = "O comentário deve ter no máximo 1000 caracteres")
            String texto
    ) {}

    public record CommentDto(
            UUID id,
            Long userId,
            String autor,
            String username,
            String photoUrl,
            String photoId,
            String texto,
            LocalDateTime createdAt,
            boolean mine,
            boolean canDelete
    ) {}

    public record FeedItemDto(DiveLogResponseDto dive, SocialSummaryDto social) {}

    public record FeedPageDto(List<FeedItemDto> items, boolean hasMore, int page) {}
}
