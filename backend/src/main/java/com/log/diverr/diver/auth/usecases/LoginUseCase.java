package com.log.diverr.diver.auth.usecases;

import com.log.diverr.diver.auth.dtos.AuthResponseDto;
import com.log.diverr.diver.common.ApiException;
import com.log.diverr.diver.auth.dtos.LoginDto;
import com.log.diverr.diver.users.domain.UserModel;
import com.log.diverr.diver.users.domain.UserStatus;
import com.log.diverr.diver.users.dtos.UserResponseDto;
import com.log.diverr.diver.users.repository.UserRepository;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class LoginUseCase {

    private final UserRepository userRepository;
    private final BCryptPasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public LoginUseCase(
            UserRepository userRepository,
            BCryptPasswordEncoder passwordEncoder,
            JwtService jwtService
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    public AuthResponseDto execute(LoginDto dto) {
        UserModel user = userRepository
                .findByEmail(dto.email().trim().toLowerCase())
                .orElseThrow(() ->
                        ApiException.unauthorized("E-mail ou senha inválidos")
                );

        if (!passwordEncoder.matches(dto.senha(), user.getSenha())) {
            throw ApiException.unauthorized("E-mail ou senha inválidos");
        }

        if (user.getStatus() != UserStatus.ATIVO) {
            throw ApiException.forbidden("Usuário não está ativo");
        }

        String token = jwtService.generateToken(user);

        return new AuthResponseDto(
                token,
                "Bearer",
                jwtService.getExpirationSeconds(),
                UserResponseDto.from(user)
        );
    }
}