package com.log.diverr.diver.bootstrap;

import com.log.diverr.diver.users.domain.UserModel;
import com.log.diverr.diver.users.repository.UserRepository;
import com.log.diverr.diver.users.usecases.UsernameGenerator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.util.List;

/** Dá @username e visibilidade padrão aos usuários criados antes do módulo de perfil. */
@Component
@Order(2)
public class UsernameBackfill implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(UsernameBackfill.class);

    private final UserRepository userRepository;
    private final UsernameGenerator generator;

    public UsernameBackfill(UserRepository userRepository, UsernameGenerator generator) {
        this.userRepository = userRepository;
        this.generator = generator;
    }

    @Override
    public void run(ApplicationArguments args) {
        List<UserModel> pending = userRepository.findByUsernameIsNull();
        for (UserModel user : pending) {
            user.setUsername(generator.generate(user.getNomeCompleto()));
            userRepository.save(user);
        }
        if (!pending.isEmpty()) {
            log.info("Username gerado para {} usuário(s)", pending.size());
        }
    }
}
