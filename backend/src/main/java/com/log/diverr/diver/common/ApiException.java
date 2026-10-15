package com.log.diverr.diver.common;

import org.springframework.http.HttpStatus;

/** Erro de negócio com status HTTP explícito, convertido em JSON pelo GlobalExceptionHandler. */
public class ApiException extends RuntimeException {

    private final HttpStatus status;
    private final String code;

    public ApiException(HttpStatus status, String message) {
        this(status, message, null);
    }

    public ApiException(HttpStatus status, String message, String code) {
        super(message);
        this.status = status;
        this.code = code;
    }

    public HttpStatus getStatus() {
        return status;
    }

    /** Código estável para o app reagir (ex.: PLAN_LIMIT). Pode ser null. */
    public String getCode() {
        return code;
    }

    public static ApiException badRequest(String message) {
        return new ApiException(HttpStatus.BAD_REQUEST, message);
    }

    public static ApiException unauthorized(String message) {
        return new ApiException(HttpStatus.UNAUTHORIZED, message);
    }

    public static ApiException forbidden(String message) {
        return new ApiException(HttpStatus.FORBIDDEN, message);
    }

    public static ApiException notFound(String message) {
        return new ApiException(HttpStatus.NOT_FOUND, message);
    }

    public static ApiException conflict(String message) {
        return new ApiException(HttpStatus.CONFLICT, message);
    }

    /** Recurso bloqueado pelo plano atual (FREE). O app mostra a oferta de upgrade. */
    public static ApiException planLimit(String message) {
        return new ApiException(HttpStatus.FORBIDDEN, message, "PLAN_LIMIT");
    }
}
