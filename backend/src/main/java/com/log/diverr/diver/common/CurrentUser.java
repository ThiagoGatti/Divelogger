package com.log.diverr.diver.common;

import org.springframework.security.oauth2.jwt.Jwt;

/** Extrai dados do usuário autenticado a partir do JWT. Nunca confie em userId vindo do corpo da requisição. */
public final class CurrentUser {

    private CurrentUser() {}

    public static Long id(Jwt jwt) {
        Object claim = jwt.getClaim("userId");
        if (claim instanceof Number n) {
            return n.longValue();
        }
        throw ApiException.unauthorized("Token inválido");
    }

    public static boolean isAdmin(Jwt jwt) {
        return "ADMIN".equals(jwt.getClaimAsString("role"));
    }
}
