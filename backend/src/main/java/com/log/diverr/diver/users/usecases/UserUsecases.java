package com.log.diverr.diver.users.usecases;
import com.log.diverr.diver.common.ApiException;
import com.log.diverr.diver.users.domain.Role;
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
    private final UsernameGenerator usernameGenerator;

    public UserUsecases(
            UserRepository userRepository,
            BCryptPasswordEncoder passwordEncoder,
            UsernameGenerator usernameGenerator
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.usernameGenerator = usernameGenerator;
    }

    public UserResponseDto execute(CreateUserDto dto) {

        if (!dto.aceitouTermosUso() || !dto.aceitouPoliticaPrivacidade()) {
            throw ApiException.badRequest(
                    "É necessário aceitar os termos de uso e a política de privacidade");
        }

        String email = dto.email().trim().toLowerCase();

        if (userRepository.existsByEmail(email)) {
            throw ApiException.conflict("E-mail já cadastrado");
        }

        UserModel user = new UserModel();
        user.setRole(Role.USER);
        user.setNomeCompleto(dto.nomeCompleto());
        user.setUsername(usernameGenerator.generate(dto.nomeCompleto()));
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