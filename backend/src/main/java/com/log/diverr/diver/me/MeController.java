package com.log.diverr.diver.me;

import com.log.diverr.diver.common.ApiException;
import com.log.diverr.diver.common.CurrentUser;
import com.log.diverr.diver.divelogs.repository.DiveLogRepository;
import com.log.diverr.diver.plans.EntitlementsDto;
import com.log.diverr.diver.plans.PlanService;
import com.log.diverr.diver.users.domain.UserModel;
import com.log.diverr.diver.users.domain.UserStatus;
import com.log.diverr.diver.users.dtos.UserResponseDto;
import com.log.diverr.diver.users.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Estado ATUAL do usuário logado (role, plano, limites). O app chama ao abrir:
 * o token pode estar desatualizado (ex.: usuário virou ADMIN/PREMIUM depois do login).
 * Também derruba usuários bloqueados antes de o token expirar.
 */
@RestController
@RequestMapping("/api/me")
public class MeController {

    public record MeResponseDto(UserResponseDto user, EntitlementsDto entitlements) {}

    private final UserRepository userRepository;
    private final DiveLogRepository diveLogRepository;
    private final PlanService planService;

    public MeController(
            UserRepository userRepository,
            DiveLogRepository diveLogRepository,
            PlanService planService
    ) {
        this.userRepository = userRepository;
        this.diveLogRepository = diveLogRepository;
        this.planService = planService;
    }

    @GetMapping
    public ResponseEntity<MeResponseDto> me(@AuthenticationPrincipal Jwt jwt) {
        UserModel user = userRepository.findById(CurrentUser.id(jwt))
                .orElseThrow(() -> ApiException.unauthorized("Usuário não encontrado"));

        if (user.getStatus() != UserStatus.ATIVO) {
            throw ApiException.unauthorized("Conta desativada");
        }

        long used = diveLogRepository.countByUserId(user.getId());
        return ResponseEntity.ok(new MeResponseDto(
                UserResponseDto.from(user),
                planService.entitlementsFor(user, used)
        ));
    }

    /** Perfil e privacidade. Só altera o que vier preenchido. */
    @PatchMapping("/profile")
    public ResponseEntity<MeResponseDto> updateProfile(
            @Valid @RequestBody ProfileUpdateDto dto,
            @AuthenticationPrincipal Jwt jwt
    ) {
        UserModel user = userRepository.findById(CurrentUser.id(jwt))
                .orElseThrow(() -> ApiException.unauthorized("Usuário não encontrado"));

        if (dto.username() != null && !dto.username().equals(user.getUsername())) {
            if (userRepository.existsByUsername(dto.username())) {
                throw ApiException.conflict("Este nome de usuário já está em uso");
            }
            user.setUsername(dto.username());
        }
        if (dto.bio() != null) {
            user.setBio(dto.bio().isBlank() ? null : dto.bio().trim());
        }
        if (dto.diveVisibility() != null) {
            user.setDiveVisibility(dto.diveVisibility());
        }
        user.setUpdatedAt(java.time.LocalDateTime.now());
        userRepository.save(user);

        long used = diveLogRepository.countByUserId(user.getId());
        return ResponseEntity.ok(new MeResponseDto(
                UserResponseDto.from(user),
                planService.entitlementsFor(user, used)
        ));
    }
}
