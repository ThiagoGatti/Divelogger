package com.log.diverr.diver.bootstrap;

import com.log.diverr.diver.users.domain.Role;
import com.log.diverr.diver.users.domain.UserModel;
import com.log.diverr.diver.users.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Cria/promove o primeiro ADMIN a partir de variáveis de ambiente (ADMIN_EMAIL e, opcionalmente, ADMIN_PASSWORD).
 * - Se o e-mail já existe: promove para ADMIN (não altera a senha).
 * - Se não existe e ADMIN_PASSWORD foi informada: cria o usuário ADMIN.
 * Sem ADMIN_EMAIL não faz nada.
 */
@Component
public class AdminBootstrap implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminBootstrap.class);

    private final UserRepository userRepository;
    private final BCryptPasswordEncoder passwordEncoder;
    private final String adminEmail;
    private final String adminPassword;

    public AdminBootstrap(
            UserRepository userRepository,
            BCryptPasswordEncoder passwordEncoder,
            @Value("${app.admin.email:}") String adminEmail,
            @Value("${app.admin.password:}") String adminPassword
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.adminEmail = adminEmail;
        this.adminPassword = adminPassword;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (adminEmail == null || adminEmail.isBlank()) {
            return;
        }
        String email = adminEmail.trim().toLowerCase();

        userRepository.findByEmail(email).ifPresentOrElse(
                existing -> {
                    if (existing.getRole() != Role.ADMIN) {
                        existing.setRole(Role.ADMIN);
                        userRepository.save(existing);
                        log.info("Usuário {} promovido a ADMIN", email);
                    }
                },
                () -> {
                    if (adminPassword == null || adminPassword.length() < 8) {
                        log.warn("ADMIN_EMAIL informado, mas usuário não existe e ADMIN_PASSWORD (min. 8) não foi definida");
                        return;
                    }
                    UserModel admin = new UserModel();
                    admin.setNomeCompleto("Administrador");
                    admin.setEmail(email);
                    admin.setSenha(passwordEncoder.encode(adminPassword));
                    admin.setRole(Role.ADMIN);
                    admin.setAceitouTermosUso(true);
                    admin.setAceitouPoliticaPrivacidade(true);
                    userRepository.save(admin);
                    log.info("Usuário ADMIN {} criado", email);
                }
        );
    }
}
