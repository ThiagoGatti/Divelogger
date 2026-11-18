package com.log.diverr.diver.me;

import com.log.diverr.diver.common.ApiException;
import com.log.diverr.diver.common.CurrentUser;
import com.log.diverr.diver.divelogs.repository.DiveLogRepository;
import com.log.diverr.diver.plans.EntitlementsDto;
import com.log.diverr.diver.plans.PlanService;
import com.log.diverr.diver.storage.ImageStorageService;
import com.log.diverr.diver.storage.PresignRequestDto;
import com.log.diverr.diver.storage.PresignResponseDto;
import com.log.diverr.diver.storage.RegisterImageDto;
import com.log.diverr.diver.users.domain.UserModel;
import com.log.diverr.diver.users.domain.UserStatus;
import com.log.diverr.diver.users.dtos.UserResponseDto;
import com.log.diverr.diver.users.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
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
    private final ImageStorageService storage;

    public MeController(
            UserRepository userRepository,
            DiveLogRepository diveLogRepository,
            PlanService planService,
            ImageStorageService storage
    ) {
        this.userRepository = userRepository;
        this.diveLogRepository = diveLogRepository;
        this.planService = planService;
        this.storage = storage;
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

    // ---------------- foto de perfil ----------------

    @PostMapping("/photo/presign")
    public ResponseEntity<PresignResponseDto> presignPhoto(
            @Valid @RequestBody PresignRequestDto dto,
            @AuthenticationPrincipal Jwt jwt
    ) {
        Long id = CurrentUser.id(jwt);
        String key = storage.newKey("users/" + id + "/avatar/", dto.contentType());
        return ResponseEntity.ok(storage.presignUpload(key, dto.contentType(), dto.sizeBytes()));
    }

    @PostMapping("/photo")
    public ResponseEntity<MeResponseDto> setPhoto(
            @Valid @RequestBody RegisterImageDto dto,
            @AuthenticationPrincipal Jwt jwt
    ) {
        Long id = CurrentUser.id(jwt);
        UserModel user = userRepository.findById(id)
                .orElseThrow(() -> ApiException.unauthorized("Usuário não encontrado"));

        if (!dto.key().startsWith("users/" + id + "/avatar/")) {
            throw ApiException.badRequest("Imagem inválida para este perfil");
        }
        storage.assertUploaded(dto.key());

        String old = user.getProfilePhotoKey();
        user.setProfilePhotoKey(dto.key());
        user.setUpdatedAt(java.time.LocalDateTime.now());
        userRepository.saveAndFlush(user);
        if (old != null && !old.equals(dto.key())) {
            storage.delete(old);
        }
        return ResponseEntity.ok(current(user));
    }

    @DeleteMapping("/photo")
    public ResponseEntity<MeResponseDto> removePhoto(@AuthenticationPrincipal Jwt jwt) {
        UserModel user = userRepository.findById(CurrentUser.id(jwt))
                .orElseThrow(() -> ApiException.unauthorized("Usuário não encontrado"));

        String old = user.getProfilePhotoKey();
        user.setProfilePhotoKey(null);
        user.setUpdatedAt(java.time.LocalDateTime.now());
        userRepository.saveAndFlush(user);
        storage.delete(old);
        return ResponseEntity.ok(current(user));
    }

    private MeResponseDto current(UserModel user) {
        long used = diveLogRepository.countByUserId(user.getId());
        return new MeResponseDto(UserResponseDto.from(user), planService.entitlementsFor(user, used));
    }
}
