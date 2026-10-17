package com.log.diverr.diver.lists;

import com.log.diverr.diver.common.CurrentUser;
import com.log.diverr.diver.lists.ListDtos.*;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/lists")
public class DiveListController {

    private final DiveListService service;

    public DiveListController(DiveListService service) {
        this.service = service;
    }

    @GetMapping("/me")
    public ResponseEntity<List<ListSummaryDto>> mine(@AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(service.listMine(CurrentUser.id(jwt)));
    }

    @PostMapping
    public ResponseEntity<ListDetailDto> create(
            @Valid @RequestBody ListRequestDto dto,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(CurrentUser.id(jwt), dto));
    }

    // ---- "Quero mergulhar" (rotas literais vêm antes de /{id}) ----

    @GetMapping("/wishlist")
    public ResponseEntity<ListDetailDto> wishlist(@AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(service.wishlist(CurrentUser.id(jwt)));
    }

    @PostMapping("/wishlist/items")
    public ResponseEntity<ListDetailDto> addToWishlist(
            @Valid @RequestBody AddItemDto dto,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.addToWishlist(CurrentUser.id(jwt), dto));
    }

    @DeleteMapping("/wishlist/items/site/{siteId}")
    public ResponseEntity<ListDetailDto> removeFromWishlist(
            @PathVariable UUID siteId,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(service.removeFromWishlist(CurrentUser.id(jwt), siteId));
    }

    // ---- "Já mergulhei" ----

    @GetMapping("/visited")
    public ResponseEntity<ListDetailDto> visited(@AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(service.visited(CurrentUser.id(jwt)));
    }

    @PostMapping("/visited/items")
    public ResponseEntity<ListDetailDto> addToVisited(
            @Valid @RequestBody AddItemDto dto,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.addToVisited(CurrentUser.id(jwt), dto));
    }

    @DeleteMapping("/visited/items/site/{siteId}")
    public ResponseEntity<ListDetailDto> removeFromVisited(
            @PathVariable UUID siteId,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(service.removeFromVisited(CurrentUser.id(jwt), siteId));
    }

    // ---- 4 favoritos ----

    @GetMapping("/favorites")
    public ResponseEntity<ListDetailDto> favorites(@AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(service.favorites(CurrentUser.id(jwt)));
    }

    @PutMapping("/favorites")
    public ResponseEntity<ListDetailDto> setFavorites(
            @Valid @RequestBody FavoritesDto dto,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(service.setFavorites(CurrentUser.id(jwt), dto.siteIds()));
    }

    // ---- listas comuns ----

    @GetMapping("/{id}")
    public ResponseEntity<ListDetailDto> get(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(service.get(id, CurrentUser.id(jwt)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ListDetailDto> update(
            @PathVariable UUID id,
            @Valid @RequestBody ListRequestDto dto,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(service.update(id, CurrentUser.id(jwt), dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt) {
        service.delete(id, CurrentUser.id(jwt));
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/items")
    public ResponseEntity<ListDetailDto> addItem(
            @PathVariable UUID id,
            @Valid @RequestBody AddItemDto dto,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.addItem(id, CurrentUser.id(jwt), dto));
    }

    @DeleteMapping("/{id}/items/{itemId}")
    public ResponseEntity<ListDetailDto> removeItem(
            @PathVariable UUID id,
            @PathVariable UUID itemId,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(service.removeItem(id, itemId, CurrentUser.id(jwt)));
    }

    @PutMapping("/{id}/items/order")
    public ResponseEntity<ListDetailDto> reorder(
            @PathVariable UUID id,
            @Valid @RequestBody ReorderDto dto,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(service.reorder(id, CurrentUser.id(jwt), dto));
    }
}
