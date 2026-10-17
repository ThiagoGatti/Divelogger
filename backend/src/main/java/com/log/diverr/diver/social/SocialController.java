package com.log.diverr.diver.social;

import com.log.diverr.diver.common.CurrentUser;
import com.log.diverr.diver.divelogs.dtos.DiveLogResponseDto;
import com.log.diverr.diver.divelogs.usecases.DiveLogService;
import com.log.diverr.diver.lists.DiveListService;
import com.log.diverr.diver.lists.ListDtos.ListDetailDto;
import com.log.diverr.diver.lists.ListDtos.ListSummaryDto;
import com.log.diverr.diver.social.SocialDtos.PublicProfileDto;
import com.log.diverr.diver.social.SocialDtos.UserSummaryDto;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Perfis públicos, seguir/deixar de seguir, busca de usuários e dados visíveis de outros usuários. */
@RestController
@RequestMapping("/api/users")
public class SocialController {

    private final FollowService followService;
    private final ProfileService profileService;
    private final DiveLogService diveLogService;
    private final DiveListService listService;

    public SocialController(
            FollowService followService,
            ProfileService profileService,
            DiveLogService diveLogService,
            DiveListService listService
    ) {
        this.followService = followService;
        this.profileService = profileService;
        this.diveLogService = diveLogService;
        this.listService = listService;
    }

    @GetMapping("/search")
    public ResponseEntity<List<UserSummaryDto>> search(
            @RequestParam(name = "q", defaultValue = "") String q,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(followService.search(q, CurrentUser.id(jwt)));
    }

    @GetMapping("/{id}/profile")
    public ResponseEntity<PublicProfileDto> profile(@PathVariable Long id, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(profileService.publicProfile(CurrentUser.id(jwt), id));
    }

    @PutMapping("/{id}/follow")
    public ResponseEntity<PublicProfileDto> follow(@PathVariable Long id, @AuthenticationPrincipal Jwt jwt) {
        followService.follow(CurrentUser.id(jwt), id);
        return ResponseEntity.ok(profileService.publicProfile(CurrentUser.id(jwt), id));
    }

    @DeleteMapping("/{id}/follow")
    public ResponseEntity<PublicProfileDto> unfollow(@PathVariable Long id, @AuthenticationPrincipal Jwt jwt) {
        followService.unfollow(CurrentUser.id(jwt), id);
        return ResponseEntity.ok(profileService.publicProfile(CurrentUser.id(jwt), id));
    }

    @GetMapping("/{id}/followers")
    public ResponseEntity<List<UserSummaryDto>> followers(@PathVariable Long id, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(followService.followers(id, CurrentUser.id(jwt)));
    }

    @GetMapping("/{id}/following")
    public ResponseEntity<List<UserSummaryDto>> following(@PathVariable Long id, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(followService.following(id, CurrentUser.id(jwt)));
    }

    @GetMapping("/{id}/friends")
    public ResponseEntity<List<UserSummaryDto>> friends(@PathVariable Long id, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(followService.friends(id, CurrentUser.id(jwt)));
    }

    /** Mergulhos de outro usuário: 403 se a privacidade dele não permitir. */
    @GetMapping("/{id}/dive-logs")
    public ResponseEntity<List<DiveLogResponseDto>> diveLogs(@PathVariable Long id, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(diveLogService.listOfUser(id, CurrentUser.id(jwt)));
    }

    @GetMapping("/{id}/lists")
    public ResponseEntity<List<ListSummaryDto>> lists(@PathVariable Long id, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(listService.listsOf(id, CurrentUser.id(jwt)));
    }

    /** Os 4 locais favoritos aparecem no perfil para todos. */
    @GetMapping("/{id}/favorites")
    public ResponseEntity<ListDetailDto> favorites(@PathVariable Long id) {
        return ResponseEntity.ok(listService.favoritesOf(id));
    }
}
