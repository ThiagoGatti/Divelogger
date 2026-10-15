package com.log.diverr.diver.divesites.dtos;

import jakarta.validation.constraints.NotNull;

public record DiveSiteStatusDto(@NotNull(message = "Informe o status") Boolean ativo) {
}
