package com.log.diverr.diver.storage;

/** O app faz PUT em uploadUrl com o header Content-Type = contentType e depois registra a key. */
public record PresignResponseDto(String uploadUrl, String key, String contentType) {
}
