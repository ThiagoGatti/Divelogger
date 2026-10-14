package com.log.diverr.diver.auth;

import com.log.diverr.diver.auth.dtos.AuthResponseDto;
import com.log.diverr.diver.auth.dtos.LoginDto;
import com.log.diverr.diver.auth.usecases.LoginUseCase;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final LoginUseCase loginUseCase;

    public AuthController(LoginUseCase loginUseCase) {
        this.loginUseCase = loginUseCase;
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponseDto> login(
            @RequestBody LoginDto dto
    ) {
        return ResponseEntity.ok(loginUseCase.execute(dto));
    }
}