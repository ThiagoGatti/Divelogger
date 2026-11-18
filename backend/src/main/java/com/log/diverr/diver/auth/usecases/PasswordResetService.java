package com.log.diverr.diver.auth.usecases;

import com.log.diverr.diver.common.ApiException;
import com.log.diverr.diver.users.domain.UserModel;
import com.log.diverr.diver.users.domain.UserStatus;
import com.log.diverr.diver.users.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;

/**
 * Recuperação de senha por CÓDIGO de 6 dígitos enviado por e-mail (sem links, para funcionar bem em app).
 *  - o código vale 15 min e fica guardado só como hash;
 *  - no máximo 5 tentativas erradas por código;
 *  - pedir de novo antes de 60 s não envia outro e-mail;
 *  - a resposta é sempre a mesma, exista ou não o e-mail (não revela quem tem conta).
 */
@Service
public class PasswordResetService {

    private static final Logger log = LoggerFactory.getLogger(PasswordResetService.class);

    private static final Duration TTL = Duration.ofMinutes(15);
    private static final Duration COOLDOWN = Duration.ofSeconds(60);
    private static final int MAX_ATTEMPTS = 5;
    private static final SecureRandom RANDOM = new SecureRandom();

    private final UserRepository users;
    private final BCryptPasswordEncoder encoder;
    private final ObjectProvider<JavaMailSender> mailSender;
    private final String from;
    private final boolean logCodes;

    public PasswordResetService(
            UserRepository users,
            BCryptPasswordEncoder encoder,
            ObjectProvider<JavaMailSender> mailSender,
            @Value("${app.mail.from:}") String from,
            @Value("${app.dev.log-reset-codes:false}") boolean logCodes
    ) {
        this.users = users;
        this.encoder = encoder;
        this.mailSender = mailSender;
        this.from = from;
        this.logCodes = logCodes;
    }

    @Transactional
    public void requestReset(String emailRaw) {
        String email = emailRaw.trim().toLowerCase();
        UserModel user = users.findByEmail(email).orElse(null);
        if (user == null || user.getStatus() != UserStatus.ATIVO) {
            return; // resposta idêntica: não revela se o e-mail existe
        }

        LocalDateTime now = LocalDateTime.now();
        LocalDateTime expires = user.getResetPasswordTokenExpiresAt();
        if (expires != null && expires.isAfter(now.plus(TTL).minus(COOLDOWN))) {
            return; // um código acabou de ser enviado
        }

        String code = String.format("%06d", RANDOM.nextInt(1_000_000));
        user.setResetPasswordToken(encoder.encode(code));
        user.setResetPasswordTokenExpiresAt(now.plus(TTL));
        user.setResetAttempts(0);
        users.save(user);

        send(user, code);
    }

    @Transactional(noRollbackFor = ApiException.class)
    public void reset(String emailRaw, String code, String newPassword) {
        final String invalid = "Código inválido ou expirado. Peça um novo código.";

        UserModel user = users.findByEmail(emailRaw.trim().toLowerCase()).orElse(null);
        if (user == null || user.getResetPasswordToken() == null
                || user.getResetPasswordTokenExpiresAt() == null
                || user.getResetPasswordTokenExpiresAt().isBefore(LocalDateTime.now())) {
            throw ApiException.badRequest(invalid);
        }

        int attempts = user.getResetAttempts() == null ? 0 : user.getResetAttempts();
        if (attempts >= MAX_ATTEMPTS) {
            clear(user);
            users.save(user);
            throw ApiException.badRequest(invalid);
        }
        if (!encoder.matches(code, user.getResetPasswordToken())) {
            user.setResetAttempts(attempts + 1);
            users.save(user);
            throw ApiException.badRequest(invalid);
        }

        user.setSenha(encoder.encode(newPassword));
        clear(user);
        users.save(user);
    }

    private static void clear(UserModel user) {
        user.setResetPasswordToken(null);
        user.setResetPasswordTokenExpiresAt(null);
        user.setResetAttempts(0);
    }

    private void send(UserModel user, String code) {
        JavaMailSender sender = mailSender.getIfAvailable();
        if (sender == null || from == null || from.isBlank()) {
            if (logCodes) {
                log.warn("[DEV] Código de recuperação de {}: {}", user.getEmail(), code);
            } else {
                log.warn("E-mail não configurado (SPRING_MAIL_HOST / MAIL_FROM): código de recuperação NÃO enviado.");
            }
            return;
        }

        try {
            String firstName = user.getNomeCompleto() == null ? "mergulhador(a)" : user.getNomeCompleto().trim().split("\\s+")[0];
            SimpleMailMessage msg = new SimpleMailMessage();
            msg.setFrom(from);
            msg.setTo(user.getEmail());
            msg.setSubject("Diverr: código para redefinir sua senha");
            msg.setText("Olá, " + firstName + "!\n\n"
                    + "Seu código para redefinir a senha do Diverr é:\n\n"
                    + "    " + code + "\n\n"
                    + "Ele vale por 15 minutos. Se você não pediu a redefinição, ignore este e-mail: "
                    + "sua senha continua a mesma.\n\n"
                    + "Equipe Diverr");
            sender.send(msg);
        } catch (Exception e) {
            log.error("Falha ao enviar e-mail de recuperação", e);
        }
    }
}
