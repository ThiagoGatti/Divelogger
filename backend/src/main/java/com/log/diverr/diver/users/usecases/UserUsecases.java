package com.log.diverr.diver.users.usecases;

import com.log.diverr.diver.users.domain.UserModel;
import com.log.diverr.diver.users.dtos.CreateUserDto;
import com.log.diverr.diver.users.dtos.UserResponseDto;
import com.log.diverr.diver.users.repository.UserRepository;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class UserUsecases {

    private final UserRepository userRepository;
    private final BCryptPasswordEncoder passwordEncoder;

    public UserUsecases(
            UserRepository userRepository,
            BCryptPasswordEncoder passwordEncoder
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public UserResponseDto execute(CreateUserDto dto) {

        String email = dto.email().trim().toLowerCase();

        if (userRepository.existsByEmail(email)) {
            throw new RuntimeException("E-mail já cadastrado");
        }

        UserModel user = new UserModel();

        user.setNomeCompleto(dto.nomeCompleto());
        user.setEmail(email);
        user.setTelefone(dto.telefone());
        user.setSenha(passwordEncoder.encode(dto.senha()));
        user.setDataNascimento(dto.dataNascimento());
        user.setAceitouTermosUso(dto.aceitouTermosUso());
        user.setAceitouPoliticaPrivacidade(dto.aceitouPoliticaPrivacidade());

        UserModel savedUser = userRepository.save(user);

        return UserResponseDto.from(savedUser);
    }
}