package com.log.diverr.diver.me;

import com.log.diverr.diver.users.domain.DiveVisibility;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** Todos os campos são opcionais: só o que for enviado é alterado. */
public record ProfileUpdateDto(
        @Pattern(regexp = "^[a-z0-9_]{3,20}$",
                message = "Usuário deve ter de 3 a 20 caracteres: letras minúsculas, números ou _")
        String username,

        @Size(max = 300, message = "A bio deve ter no máximo 300 caracteres")
        String bio,

        DiveVisibility diveVisibility
) {
}
