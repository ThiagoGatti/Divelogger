package com.log.diverr.diver.lists;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

public final class ListDtos {

    private ListDtos() {}

    public record ListRequestDto(
            @NotBlank(message = "Dê um nome para a lista")
            @Size(max = 120, message = "Nome muito longo (máx. 120)")
            String nome,

            @Size(max = 500, message = "Descrição muito longa (máx. 500)")
            String descricao,

            Boolean ranked
    ) {}

    public record AddItemDto(
            @NotNull(message = "Selecione o Dive Site")
            UUID siteId,

            @Size(max = 500, message = "Nota muito longa (máx. 500)")
            String nota
    ) {}

    public record FavoritesDto(
            @NotNull(message = "Informe os locais favoritos")
            List<UUID> siteIds
    ) {}

    public record ReorderDto(
            @NotNull(message = "Informe a nova ordem")
            List<UUID> itemIds
    ) {}

    public record ListItemDto(
            UUID id,
            int position,
            String nota,
            UUID siteId,
            String siteNome,
            String localizacao,
            String tipo,
            boolean ativo,
            String coverUrl,
            String coverImageId
    ) {}

    public record ListSummaryDto(
            UUID id,
            String nome,
            String descricao,
            boolean ranked,
            String tipo,
            int itemsCount,
            String coverUrl,
            String coverImageId
    ) {}

    public record ListDetailDto(
            UUID id,
            String nome,
            String descricao,
            boolean ranked,
            String tipo,
            List<ListItemDto> items
    ) {}
}
