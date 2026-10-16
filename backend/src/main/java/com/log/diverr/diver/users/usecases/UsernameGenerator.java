package com.log.diverr.diver.users.usecases;

import com.log.diverr.diver.users.repository.UserRepository;
import org.springframework.stereotype.Component;

import java.security.SecureRandom;
import java.text.Normalizer;

/** Gera @usernames únicos a partir do nome (ex.: "Ana Souza" -> "ana4821"). */
@Component
public class UsernameGenerator {

    private static final SecureRandom RANDOM = new SecureRandom();

    private final UserRepository userRepository;

    public UsernameGenerator(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public String generate(String nomeCompleto) {
        String base = slug(nomeCompleto);
        if (base.length() < 3) {
            base = "diver";
        }
        if (base.length() > 12) {
            base = base.substring(0, 12);
        }

        for (int i = 0; i < 30; i++) {
            String candidate = base + (1000 + RANDOM.nextInt(9000));
            if (!userRepository.existsByUsername(candidate)) {
                return candidate;
            }
        }
        return base + System.currentTimeMillis() % 1_000_000;
    }

    static String slug(String name) {
        if (name == null) return "";
        String first = name.trim().split("\\s+")[0];
        String normalized = Normalizer.normalize(first, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase()
                .replaceAll("[^a-z0-9]", "");
        return normalized;
    }
}
