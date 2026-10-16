package com.log.diverr.diver.reviews;

import com.log.diverr.diver.common.CurrentUser;
import com.log.diverr.diver.reviews.ReviewDtos.ReviewRequestDto;
import com.log.diverr.diver.reviews.ReviewDtos.ReviewsResponseDto;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * Avaliações e comentários de locais. Fica fora de /api/dive-sites/** de propósito:
 * naquele prefixo, escrita é exclusiva de ADMIN.
 */
@RestController
@RequestMapping("/api/site-reviews")
public class DiveSiteReviewController {

    private final DiveSiteReviewService service;

    public DiveSiteReviewController(DiveSiteReviewService service) {
        this.service = service;
    }

    @GetMapping("/{siteId}")
    public ResponseEntity<ReviewsResponseDto> list(
            @PathVariable UUID siteId,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(service.list(siteId, CurrentUser.id(jwt), CurrentUser.isAdmin(jwt)));
    }

    @PutMapping("/{siteId}/me")
    public ResponseEntity<ReviewsResponseDto> upsertMine(
            @PathVariable UUID siteId,
            @Valid @RequestBody ReviewRequestDto dto,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(service.upsertMine(siteId, CurrentUser.id(jwt), dto));
    }

    @DeleteMapping("/{siteId}/me")
    public ResponseEntity<ReviewsResponseDto> deleteMine(
            @PathVariable UUID siteId,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(service.deleteMine(siteId, CurrentUser.id(jwt)));
    }

    @DeleteMapping("/{siteId}/{reviewId}")
    public ResponseEntity<ReviewsResponseDto> deleteAny(
            @PathVariable UUID siteId,
            @PathVariable UUID reviewId,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(
                service.deleteAny(siteId, reviewId, CurrentUser.id(jwt), CurrentUser.isAdmin(jwt)));
    }
}
