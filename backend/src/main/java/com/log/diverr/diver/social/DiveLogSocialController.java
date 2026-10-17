package com.log.diverr.diver.social;

import com.log.diverr.diver.common.CurrentUser;
import com.log.diverr.diver.social.SocialDtos.CommentDto;
import com.log.diverr.diver.social.SocialDtos.CommentRequestDto;
import com.log.diverr.diver.social.SocialDtos.ReactionRequestDto;
import com.log.diverr.diver.social.SocialDtos.SocialSummaryDto;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/** Reações e comentários em um mergulho (só para quem pode vê-lo). */
@RestController
@RequestMapping("/api/dive-logs")
public class DiveLogSocialController {

    private final DiveLogSocialService service;

    public DiveLogSocialController(DiveLogSocialService service) {
        this.service = service;
    }

    @GetMapping("/{id}/social")
    public ResponseEntity<SocialSummaryDto> summary(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(service.summary(id, CurrentUser.id(jwt)));
    }

    @PutMapping("/{id}/reaction")
    public ResponseEntity<SocialSummaryDto> react(
            @PathVariable UUID id,
            @Valid @RequestBody ReactionRequestDto dto,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(service.react(id, CurrentUser.id(jwt), dto.emoji()));
    }

    @DeleteMapping("/{id}/reaction")
    public ResponseEntity<SocialSummaryDto> removeReaction(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(service.removeReaction(id, CurrentUser.id(jwt)));
    }

    @GetMapping("/{id}/comments")
    public ResponseEntity<List<CommentDto>> comments(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(service.listComments(id, CurrentUser.id(jwt), CurrentUser.isAdmin(jwt)));
    }

    @PostMapping("/{id}/comments")
    public ResponseEntity<List<CommentDto>> addComment(
            @PathVariable UUID id,
            @Valid @RequestBody CommentRequestDto dto,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(service.addComment(id, CurrentUser.id(jwt), dto.texto(), CurrentUser.isAdmin(jwt)));
    }

    @DeleteMapping("/{id}/comments/{commentId}")
    public ResponseEntity<List<CommentDto>> deleteComment(
            @PathVariable UUID id,
            @PathVariable UUID commentId,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(
                service.deleteComment(id, commentId, CurrentUser.id(jwt), CurrentUser.isAdmin(jwt)));
    }
}
