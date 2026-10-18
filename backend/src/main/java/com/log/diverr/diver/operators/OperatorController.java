package com.log.diverr.diver.operators;

import com.log.diverr.diver.common.CurrentUser;
import com.log.diverr.diver.operators.OperatorDtos.*;
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

/** Leitura: qualquer usuário autenticado. Escrita (POST/PUT/PATCH/DELETE): somente ADMIN (SecurityConfig). */
@RestController
@RequestMapping("/api/operators")
public class OperatorController {

    private final OperatorService service;

    public OperatorController(OperatorService service) {
        this.service = service;
    }

    @GetMapping
    public ResponseEntity<List<OperatorSummaryDto>> list(
            @RequestParam(defaultValue = "false") boolean includeInactive,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(service.list(includeInactive, CurrentUser.isAdmin(jwt)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<OperatorDetailDto> get(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(service.get(id, CurrentUser.isAdmin(jwt)));
    }

    @PostMapping
    public ResponseEntity<OperatorDetailDto> create(@Valid @RequestBody OperatorRequestDto dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(dto));
    }

    @PutMapping("/{id}")
    public ResponseEntity<OperatorDetailDto> update(
            @PathVariable UUID id,
            @Valid @RequestBody OperatorRequestDto dto
    ) {
        return ResponseEntity.ok(service.update(id, dto));
    }

    @PatchMapping("/{id}/ativo")
    public ResponseEntity<OperatorDetailDto> setAtivo(
            @PathVariable UUID id,
            @Valid @RequestBody OperatorStatusDto dto
    ) {
        return ResponseEntity.ok(service.setAtivo(id, dto.ativo()));
    }

    @PutMapping("/{id}/sites")
    public ResponseEntity<OperatorDetailDto> setSites(
            @PathVariable UUID id,
            @Valid @RequestBody SiteIdsDto dto
    ) {
        return ResponseEntity.ok(service.setSites(id, dto.siteIds()));
    }

    @PostMapping("/{id}/photo/presign")
    public ResponseEntity<PresignResponseDto> presign(
            @PathVariable UUID id,
            @Valid @RequestBody PresignRequestDto dto
    ) {
        return ResponseEntity.ok(service.presignPhoto(id, dto));
    }

    @PostMapping("/{id}/photo")
    public ResponseEntity<OperatorDetailDto> setPhoto(
            @PathVariable UUID id,
            @Valid @RequestBody RegisterImageDto dto
    ) {
        return ResponseEntity.ok(service.setPhoto(id, dto.key()));
    }

    @DeleteMapping("/{id}/photo")
    public ResponseEntity<OperatorDetailDto> removePhoto(@PathVariable UUID id) {
        return ResponseEntity.ok(service.removePhoto(id));
    }
}
