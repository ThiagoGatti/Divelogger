package com.log.diverr.diver.auth.usecases;

import com.log.diverr.diver.users.domain.UserModel;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

import java.time.Instant;

@Service
public class JwtService {

    private final JwtEncoder jwtEncoder;
    private final long expirationMs;

    public JwtService(
            JwtEncoder jwtEncoder,
            @Value("${app.jwt.expiration-ms}") long expirationMs
    ) {
        this.jwtEncoder = jwtEncoder;
        this.expirationMs = expirationMs;
    }

    public String generateToken(UserModel user) {
        Instant now = Instant.now();

        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer("diverr-api")
                .issuedAt(now)
                .expiresAt(now.plusMillis(expirationMs))
                .subject(user.getEmail())
                .claim("userId", user.getId())
                .claim("role", user.getRole().name())
                .build();

        JwsHeader header = JwsHeader
                .with(MacAlgorithm.HS256)
                .build();

        return jwtEncoder.encode(
                JwtEncoderParameters.from(header, claims)
        ).getTokenValue();
    }

    public long getExpirationSeconds() {
        return expirationMs / 1000;
    }
}