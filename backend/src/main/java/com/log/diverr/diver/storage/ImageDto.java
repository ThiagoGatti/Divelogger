package com.log.diverr.diver.storage;

import java.util.UUID;

/** Imagem devolvida ao app: id (para cache/remoção) + URL temporária de leitura. */
public record ImageDto(UUID id, String url) {
}
