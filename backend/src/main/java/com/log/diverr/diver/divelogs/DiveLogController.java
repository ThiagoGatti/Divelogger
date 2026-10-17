package com.log.diverr.diver.divelogs;

import com.log.diverr.diver.common.CurrentUser;
import com.log.diverr.diver.divelogs.dtos.CreateDiveLogDto;
import com.log.diverr.diver.divelogs.dtos.DiveLogResponseDto;
import com.log.diverr.diver.divelogs.usecases.DiveLogService;
import com.log.diverr.diver.storage.PresignRequestDto;
import com.log.diverr.diver.storage.PresignResponseDto;
import com.log.diverr.diver.storage.RegisterImageDto;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Cada usuário só enxerga/edita os PRÓPRIOS mergulhos. O dono sempre vem do token.
 * (O módulo social vai adicionar visibilidade por privacidade depois.)
 */
@RestController
@RequestMapping("/api/dive-logs")
public class DiveLogController {

    private final DiveLogService service;

    public DiveLogController(DiveLogService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<DiveLogResponseDto> create(
            @Valid @RequestBody CreateDiveLogDto dto,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(dto, CurrentUser.id(jwt)));
    }

    @GetMapping("/me")
    public ResponseEntity<List<DiveLogResponseDto>> findMine(@AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(service.listMine(CurrentUser.id(jwt)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<DiveLogResponseDto> findById(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(service.get(id, CurrentUser.id(jwt)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<DiveLogResponseDto> update(
            @PathVariable UUID id,
            @Valid @RequestBody CreateDiveLogDto dto,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(service.update(id, dto, CurrentUser.id(jwt)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt) {
        service.delete(id, CurrentUser.id(jwt));
        return ResponseEntity.noContent().build();
    }

    /** Mergulhos de um usuário: o próprio ou, se a privacidade dele permitir, de outra pessoa. */
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<DiveLogResponseDto>> findByUser(
            @PathVariable Long userId,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(service.listOfUser(userId, CurrentUser.id(jwt)));
    }

    /** Meus mergulhos em um Dive Site. */
    @GetMapping("/site/{diveSiteId}")
    public ResponseEntity<List<DiveLogResponseDto>> findByDiveSite(
            @PathVariable UUID diveSiteId,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(service.listMineBySite(diveSiteId, CurrentUser.id(jwt)));
    }

    // ---- imagens ----

    @PostMapping("/{id}/images/presign")
    public ResponseEntity<PresignResponseDto> presign(
            @PathVariable UUID id,
            @Valid @RequestBody PresignRequestDto dto,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(service.presignImage(id, CurrentUser.id(jwt), dto));
    }

    @PostMapping("/{id}/images")
    public ResponseEntity<DiveLogResponseDto> addImage(
            @PathVariable UUID id,
            @Valid @RequestBody RegisterImageDto dto,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(service.addImage(id, CurrentUser.id(jwt), dto.key()));
    }

    @DeleteMapping("/{id}/images/{imageId}")
    public ResponseEntity<DiveLogResponseDto> removeImage(
            @PathVariable UUID id,
            @PathVariable UUID imageId,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(service.removeImage(id, imageId, CurrentUser.id(jwt)));
    }
}
