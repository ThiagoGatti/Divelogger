package com.log.diverr.diver.admin;

import com.log.diverr.diver.common.ApiException;
import com.log.diverr.diver.users.domain.UserModel;
import com.log.diverr.diver.users.dtos.UserResponseDto;
import com.log.diverr.diver.users.repository.UserRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Painel administrativo (somente ADMIN: /api/admin/** no SecurityConfig).
 * Enquanto não há pagamento in-app, é aqui que se concede/remove o plano Premium.
 */
@RestController
@RequestMapping("/api/admin/users")
public class AdminUserController {

    public record PlanUpdateDto(
            @NotNull(message = "Informe o plano") UserModel.Plano plano,
            LocalDate planExpiresAt
    ) {}

    private final UserRepository userRepository;

    public AdminUserController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping
    public ResponseEntity<List<UserResponseDto>> list() {
        return ResponseEntity.ok(
                userRepository.findAll().stream().map(UserResponseDto::from).toList()
        );
    }

    @PatchMapping("/{id}/plan")
    public ResponseEntity<UserResponseDto> updatePlan(
            @PathVariable Long id,
            @Valid @RequestBody PlanUpdateDto dto
    ) {
        UserModel user = userRepository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Usuário não encontrado"));

        user.setPlano(dto.plano());
        user.setPlanExpiresAt(dto.plano() == UserModel.Plano.PREMIUM ? dto.planExpiresAt() : null);
        user.setUpdatedAt(LocalDateTime.now());

        return ResponseEntity.ok(UserResponseDto.from(userRepository.save(user)));
    }
}
