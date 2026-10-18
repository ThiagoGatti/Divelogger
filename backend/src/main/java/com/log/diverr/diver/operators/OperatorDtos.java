package com.log.diverr.diver.operators;

import com.log.diverr.diver.storage.ImageStorageService;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

public final class OperatorDtos {

    private OperatorDtos() {}

    public record OperatorRequestDto(
            @NotBlank(message = "Nome da operadora é obrigatório")
            @Size(max = 150, message = "Nome muito longo (máx. 150)")
            String nome,

            @Size(max = 300, message = "Endereço muito longo (máx. 300)")
            String endereco
    ) {}

    public record OperatorStatusDto(@NotNull(message = "Informe o status") Boolean ativo) {}

    public record SiteIdsDto(@NotNull(message = "Informe os locais") List<UUID> siteIds) {}

    public record OperatorIdsDto(@NotNull(message = "Informe as operadoras") List<UUID> operatorIds) {}

    /** Foto: photoId é estável (serve de chave de cache no app); photoUrl muda a cada resposta. */
    public record OperatorSummaryDto(
            UUID id,
            String nome,
            String endereco,
            String photoUrl,
            String photoId,
            boolean ativo
    ) {
        public static OperatorSummaryDto from(OperatorModel o, ImageStorageService storage) {
            return new OperatorSummaryDto(
                    o.getId(),
                    o.getNome(),
                    o.getEndereco(),
                    o.getPhotoKey() == null ? null : storage.urlFor(o.getPhotoKey()),
                    o.getPhotoKey() == null ? null : UUID.nameUUIDFromBytes(o.getPhotoKey().getBytes()).toString(),
                    o.isAtivo()
            );
        }
    }

    public record SiteRefDto(UUID id, String nome, String localizacao, boolean ativo) {}

    public record OperatorDetailDto(
            UUID id,
            String nome,
            String endereco,
            String photoUrl,
            String photoId,
            boolean ativo,
            List<SiteRefDto> sites
    ) {}
}
