package com.log.diverr.diver.auth;

import com.log.diverr.diver.auth.dtos.AuthResponseDto;
import com.log.diverr.diver.auth.dtos.ForgotPasswordDto;
import com.log.diverr.diver.auth.dtos.GoogleLoginDto;
import com.log.diverr.diver.auth.dtos.ResetPasswordDto;
import com.log.diverr.diver.auth.usecases.GoogleAuthService;
import com.log.diverr.diver.auth.usecases.PasswordResetService;
import com.log.diverr.diver.auth.dtos.LoginDto;
import com.log.diverr.diver.auth.usecases.LoginUseCase;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final LoginUseCase loginUseCase;
    private final PasswordResetService passwordResetService;
    private final GoogleAuthService googleAuthService;

    public AuthController(
            LoginUseCase loginUseCase,
            PasswordResetService passwordResetService,
            GoogleAuthService googleAuthService
    ) {
        this.loginUseCase = loginUseCase;
        this.passwordResetService = passwordResetService;
        this.googleAuthService = googleAuthService;
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponseDto> login(
            @Valid @RequestBody LoginDto dto
    ) {
        return ResponseEntity.ok(loginUseCase.execute(dto));
    }

    /** Envia um código de 6 dígitos por e-mail. A resposta é sempre a mesma (não revela se o e-mail existe). */
    @PostMapping("/forgot-password")
    public ResponseEntity<Map<String, String>> forgotPassword(
            @Valid @RequestBody ForgotPasswordDto dto
    ) {
        passwordResetService.requestReset(dto.email());
        return ResponseEntity.ok(Map.of(
                "message", "Se este e-mail tiver uma conta, enviamos um código para redefinir a senha."));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<Map<String, String>> resetPassword(
            @Valid @RequestBody ResetPasswordDto dto
    ) {
        passwordResetService.reset(dto.email(), dto.code(), dto.newPassword());
        return ResponseEntity.ok(Map.of("message", "Senha redefinida. Entre com a nova senha."));
    }

    /** Login com Google: o ID token é validado no servidor. */
    @PostMapping("/google")
    public ResponseEntity<AuthResponseDto> google(
            @Valid @RequestBody GoogleLoginDto dto
    ) {
        return ResponseEntity.ok(
                googleAuthService.login(dto.idToken(), Boolean.TRUE.equals(dto.acceptedTerms())));
    }
}
