package com.log.diverr.diver.auth.usecases;

import com.log.diverr.diver.auth.dtos.LoginDto;
import com.log.diverr.diver.users.domain.UserModel;
import com.log.diverr.diver.users.dtos.UserResponseDto;
import com.log.diverr.diver.users.repository.UserRepository;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class LoginUseCase {
    private final UserRepository userRepository;
    private final BCryptPasswordEncoder passwordEncoder;

    public LoginUseCase(UserRepository userRepository, BCryptPasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public UserResponseDto execute(LoginDto dto) {
        UserModel user = userRepository.findByEmail(dto.email().trim().toLowerCase())
                .orElseThrow(() -> new IllegalArgumentException("E-mail ou senha inválidos"));

        if (!passwordEncoder.matches(dto.senha(), user.getSenha())) {
            throw new IllegalArgumentException("E-mail ou senha inválidos");
        }

        if (user.getStatus() != com.log.diverr.diver.users.domain.UserStatus.ATIVO) {
            throw new IllegalArgumentException("Usuário não está ativo");
        }

        return UserResponseDto.from(user);
    }
}
