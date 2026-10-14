package com.log.diverr.diver.divelogs;

import com.log.diverr.diver.common.ApiException;
import com.log.diverr.diver.common.CurrentUser;
import com.log.diverr.diver.divelogs.domain.DiveLogModel;
import com.log.diverr.diver.divelogs.dtos.CreateDiveLogDto;
import com.log.diverr.diver.divelogs.dtos.DiveLogResponseDto;
import com.log.diverr.diver.divelogs.repository.DiveLogRepository;
import com.log.diverr.diver.divelogs.usecases.CreateDiveLogUseCase;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Regra atual (antes do módulo social): cada usuário só enxerga os PRÓPRIOS mergulhos.
 * O dono sempre vem do token, nunca do corpo da requisição.
 */
@RestController
@RequestMapping("/api/dive-logs")
public class DiveLogController {

    private final CreateDiveLogUseCase createDiveLogUseCase;
    private final DiveLogRepository diveLogRepository;

    public DiveLogController(
            CreateDiveLogUseCase createDiveLogUseCase,
            DiveLogRepository diveLogRepository
    ) {
        this.createDiveLogUseCase = createDiveLogUseCase;
        this.diveLogRepository = diveLogRepository;
    }

    @PostMapping
    @Transactional
    public ResponseEntity<DiveLogResponseDto> create(
            @RequestBody CreateDiveLogDto dto,
            @AuthenticationPrincipal Jwt jwt
    ) {
        DiveLogResponseDto response =
                createDiveLogUseCase.execute(dto, CurrentUser.id(jwt));

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /** Meus mergulhos. */
    @GetMapping("/me")
    @Transactional(readOnly = true)
    public ResponseEntity<List<DiveLogResponseDto>> findMine(
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(
                diveLogRepository.findByUserId(CurrentUser.id(jwt))
                        .stream()
                        .map(DiveLogResponseDto::from)
                        .toList()
        );
    }

    @GetMapping("/{id}")
    @Transactional(readOnly = true)
    public ResponseEntity<DiveLogResponseDto> findById(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt
    ) {
        DiveLogModel diveLog = diveLogRepository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Dive log não encontrado"));

        // 404 (e não 403) para não revelar a existência de logs de outras pessoas
        if (!diveLog.getUser().getId().equals(CurrentUser.id(jwt)) && !CurrentUser.isAdmin(jwt)) {
            throw ApiException.notFound("Dive log não encontrado");
        }

        return ResponseEntity.ok(DiveLogResponseDto.from(diveLog));
    }

    /** Compatibilidade: só o próprio usuário (ou admin) pode listar por userId. */
    @GetMapping("/user/{userId}")
    @Transactional(readOnly = true)
    public ResponseEntity<List<DiveLogResponseDto>> findByUser(
            @PathVariable Long userId,
            @AuthenticationPrincipal Jwt jwt
    ) {
        if (!userId.equals(CurrentUser.id(jwt)) && !CurrentUser.isAdmin(jwt)) {
            throw ApiException.forbidden("Você não tem permissão para ver estes mergulhos");
        }

        return ResponseEntity.ok(
                diveLogRepository.findByUserId(userId)
                        .stream()
                        .map(DiveLogResponseDto::from)
                        .toList()
        );
    }

    /** Meus mergulhos em um determinado Dive Site. */
    @GetMapping("/site/{diveSiteId}")
    @Transactional(readOnly = true)
    public ResponseEntity<List<DiveLogResponseDto>> findByDiveSite(
            @PathVariable UUID diveSiteId,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ResponseEntity.ok(
                diveLogRepository.findByDiveSiteIdAndUserId(diveSiteId, CurrentUser.id(jwt))
                        .stream()
                        .map(DiveLogResponseDto::from)
                        .toList()
        );
    }
}
