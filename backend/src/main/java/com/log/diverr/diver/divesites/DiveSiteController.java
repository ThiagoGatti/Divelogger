package com.log.diverr.diver.divesites;

import com.log.diverr.diver.common.CurrentUser;
import com.log.diverr.diver.divesites.dtos.CreateDiveSiteDto;
import com.log.diverr.diver.divesites.dtos.DiveSiteResponseDto;
import com.log.diverr.diver.divesites.dtos.DiveSiteStatusDto;
import com.log.diverr.diver.divesites.usecases.DiveSiteService;
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
 * Leitura (GET): qualquer usuário autenticado.
 * Escrita (POST/PUT/PATCH/DELETE): somente ADMIN — regra no SecurityConfig.
 */
@RestController
@RequestMapping("/api/dive-sites")
public class DiveSiteController {

    private final DiveSiteService service;

    public DiveSiteController(DiveSiteService service) {
        this.service = service;
    }

    @GetMapping
    public ResponseEntity<List<DiveSiteResponseDto>> findAll(
            @RequestParam(defaultValue = "false") boolean includeInactive,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(service.list(includeInactive, CurrentUser.isAdmin(jwt)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<DiveSiteResponseDto> findById(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(service.get(id, CurrentUser.isAdmin(jwt)));
    }

    @PostMapping
    public ResponseEntity<DiveSiteResponseDto> create(
            @Valid @RequestBody CreateDiveSiteDto dto,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(service.create(dto, CurrentUser.id(jwt)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<DiveSiteResponseDto> update(
            @PathVariable UUID id,
            @Valid @RequestBody CreateDiveSiteDto dto
    ) {
        return ResponseEntity.ok(service.update(id, dto));
    }

    /** Ativar / desativar (exclusão lógica). */
    @PatchMapping("/{id}/ativo")
    public ResponseEntity<DiveSiteResponseDto> setAtivo(
            @PathVariable UUID id,
            @Valid @RequestBody DiveSiteStatusDto dto
    ) {
        return ResponseEntity.ok(service.setAtivo(id, dto.ativo()));
    }

    // ---- imagens ----

    @PostMapping("/{id}/images/presign")
    public ResponseEntity<PresignResponseDto> presign(
            @PathVariable UUID id,
            @Valid @RequestBody PresignRequestDto dto
    ) {
        return ResponseEntity.ok(service.presignImage(id, dto));
    }

    @PostMapping("/{id}/images")
    public ResponseEntity<DiveSiteResponseDto> addImage(
            @PathVariable UUID id,
            @Valid @RequestBody RegisterImageDto dto
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.addImage(id, dto.key()));
    }

    @DeleteMapping("/{id}/images/{imageId}")
    public ResponseEntity<DiveSiteResponseDto> removeImage(
            @PathVariable UUID id,
            @PathVariable UUID imageId
    ) {
        return ResponseEntity.ok(service.removeImage(id, imageId));
    }
}
