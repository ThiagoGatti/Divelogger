package com.log.diverr.diver.auth.usecases;

import com.log.diverr.diver.auth.dtos.AuthResponseDto;
import com.log.diverr.diver.common.ApiException;
import com.log.diverr.diver.users.domain.Role;
import com.log.diverr.diver.users.domain.UserModel;
import com.log.diverr.diver.users.domain.UserStatus;
import com.log.diverr.diver.users.dtos.UserResponseDto;
import com.log.diverr.diver.users.repository.UserRepository;
import com.log.diverr.diver.users.usecases.UsernameGenerator;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.JwtTimestampValidator;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Login com Google. O app envia o ID token; aqui ele é VALIDADO no servidor (assinatura do Google,
 * validade, emissor e público/cliente). Nunca confiamos em e-mail enviado pelo app.
 *  - conta existente com o mesmo e-mail (verificado pelo Google): vincula e entra;
 *  - conta nova: exige que o usuário tenha aceito os Termos e a Política.
 */
@Service
public class GoogleAuthService {

    private static final String JWKS = "https://www.googleapis.com/oauth2/v3/certs";
    private static final Set<String> ISSUERS = Set.of("accounts.google.com", "https://accounts.google.com");

    private final Set<String> clientIds;
    private final UserRepository users;
    private final BCryptPasswordEncoder encoder;
    private final JwtService jwtService;
    private final UsernameGenerator usernames;

    private volatile JwtDecoder decoder;

    public GoogleAuthService(
            @Value("${app.google.client-ids:}") String clientIds,
            UserRepository users,
            BCryptPasswordEncoder encoder,
            JwtService jwtService,
            UsernameGenerator usernames
    ) {
        this.clientIds = Arrays.stream(clientIds.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toSet());
        this.users = users;
        this.encoder = encoder;
        this.jwtService = jwtService;
        this.usernames = usernames;
    }

    @Transactional
    public AuthResponseDto login(String idToken, boolean acceptedTerms) {
        if (clientIds.isEmpty()) {
            throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "Login com Google não está configurado");
        }

        Jwt jwt;
        try {
            jwt = decoder().decode(idToken);
        } catch (JwtException e) {
            throw ApiException.unauthorized("Não foi possível validar o login com o Google");
        }

        String sub = jwt.getSubject();
        String email = jwt.getClaimAsString("email");
        Boolean verified = jwt.getClaim("email_verified");
        String name = jwt.getClaimAsString("name");

        if (sub == null || email == null || !Boolean.TRUE.equals(verified)) {
            throw ApiException.unauthorized("O e-mail da sua conta Google não está verificado");
        }
        String normalized = email.trim().toLowerCase();

        UserModel user = users.findByGoogleSub(sub)
                .or(() -> users.findByEmail(normalized))
                .orElse(null);

        if (user == null) {
            if (!acceptedTerms) {
                throw new ApiException(
                        HttpStatus.BAD_REQUEST,
                        "É necessário aceitar os Termos de Uso e a Política de Privacidade para criar a conta",
                        "TERMS_REQUIRED");
            }
            String display = (name == null || name.isBlank()) ? normalized.substring(0, normalized.indexOf('@')) : name;

            user = new UserModel();
            user.setNomeCompleto(display);
            user.setEmail(normalized);
            user.setUsername(usernames.generate(display));
            // conta sem senha própria: senha aleatória inutilizável (o usuário pode criar uma via "Esqueci minha senha")
            user.setSenha(encoder.encode(UUID.randomUUID() + UUID.randomUUID().toString()));
            user.setRole(Role.USER);
            user.setStatus(UserStatus.ATIVO);
            user.setAceitouTermosUso(true);
            user.setAceitouPoliticaPrivacidade(true);
        } else if (user.getStatus() != UserStatus.ATIVO) {
            throw ApiException.forbidden("Usuário não está ativo");
        }

        user.setGoogleSub(sub);
        user.setVerificado(true); // o Google já verificou o e-mail
        user = users.save(user);

        return new AuthResponseDto(
                jwtService.generateToken(user),
                "Bearer",
                jwtService.getExpirationSeconds(),
                UserResponseDto.from(user)
        );
    }

    private JwtDecoder decoder() {
        JwtDecoder d = decoder;
        if (d == null) {
            synchronized (this) {
                d = decoder;
                if (d == null) {
                    NimbusJwtDecoder nimbus = NimbusJwtDecoder.withJwkSetUri(JWKS).build();

                    OAuth2TokenValidator<Jwt> issuerAndAudience = token -> {
                        String iss = token.getClaimAsString("iss");
                        List<String> aud = token.getAudience();
                        boolean issuerOk = iss != null && ISSUERS.contains(iss);
                        boolean audienceOk = aud != null && aud.stream().anyMatch(clientIds::contains);
                        return (issuerOk && audienceOk)
                                ? OAuth2TokenValidatorResult.success()
                                : OAuth2TokenValidatorResult.failure(
                                        new OAuth2Error("invalid_token", "Emissor ou público inválido", null));
                    };

                    nimbus.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
                            new JwtTimestampValidator(), issuerAndAudience));
                    decoder = d = nimbus;
                }
            }
        }
        return d;
    }
}
