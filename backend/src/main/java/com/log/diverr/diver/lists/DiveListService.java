package com.log.diverr.diver.lists;

import com.log.diverr.diver.common.ApiException;
import com.log.diverr.diver.divesites.domain.DiveSiteImageModel;
import com.log.diverr.diver.divesites.domain.DiveSiteModel;
import com.log.diverr.diver.divesites.repository.DiveSiteRepository;
import com.log.diverr.diver.lists.ListDtos.*;
import com.log.diverr.diver.social.VisibilityService;
import com.log.diverr.diver.storage.ImageStorageService;
import com.log.diverr.diver.users.domain.UserModel;
import com.log.diverr.diver.users.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;

/**
 * Listas de Dive Sites. Escrita: só o dono. Leitura de listas de OUTRAS pessoas: só listas comuns
 * (tipo LISTA) e somente se a privacidade do dono permitir (VisibilityService).
 */
@Service
public class DiveListService {

    private static final int MAX_LISTS_PER_USER = 100;
    private static final int MAX_ITEMS_PER_LIST = 500;
    public static final int MAX_FAVORITES = 4;

    private final DiveListRepository repository;
    private final DiveSiteRepository siteRepository;
    private final UserRepository userRepository;
    private final ImageStorageService storage;
    private final VisibilityService visibility;

    public DiveListService(
            DiveListRepository repository,
            DiveSiteRepository siteRepository,
            UserRepository userRepository,
            ImageStorageService storage,
            VisibilityService visibility
    ) {
        this.repository = repository;
        this.siteRepository = siteRepository;
        this.userRepository = userRepository;
        this.storage = storage;
        this.visibility = visibility;
    }

    // ---------------- listas comuns ----------------

    @Transactional(readOnly = true)
    public List<ListSummaryDto> listMine(Long userId) {
        return repository.findByOwnerIdOrderByCreatedAtDesc(userId).stream()
                .filter(l -> l.getTipo() == DiveListModel.Tipo.LISTA)
                .map(this::summary)
                .toList();
    }

    /** Listas comuns de outro usuário, se a privacidade dele permitir. */
    @Transactional(readOnly = true)
    public List<ListSummaryDto> listsOf(Long ownerId, Long viewerId) {
        UserModel owner = user(ownerId);
        if (!visibility.canViewDives(viewerId, owner)) {
            throw ApiException.forbidden("Este usuário não compartilha as listas com você");
        }
        return listMine(ownerId);
    }

    @Transactional
    public ListDetailDto create(Long userId, ListRequestDto dto) {
        UserModel owner = user(userId);
        long existing = repository.findByOwnerIdOrderByCreatedAtDesc(userId).stream()
                .filter(l -> l.getTipo() == DiveListModel.Tipo.LISTA).count();
        if (existing >= MAX_LISTS_PER_USER) {
            throw ApiException.badRequest("Limite de " + MAX_LISTS_PER_USER + " listas atingido");
        }

        DiveListModel list = new DiveListModel();
        list.setOwner(owner);
        list.setNome(dto.nome().trim());
        list.setDescricao(blankToNull(dto.descricao()));
        list.setRanked(Boolean.TRUE.equals(dto.ranked()));
        return detail(repository.saveAndFlush(list));
    }

    /** Dono vê qualquer lista dele; outras pessoas só veem listas comuns que a privacidade permitir. */
    @Transactional(readOnly = true)
    public ListDetailDto get(UUID id, Long viewerId) {
        DiveListModel list = repository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Lista não encontrada"));
        boolean owner = list.getOwner().getId().equals(viewerId);
        if (!owner) {
            boolean allowed = list.getTipo() == DiveListModel.Tipo.LISTA
                    && visibility.canViewDives(viewerId, list.getOwner());
            if (!allowed) {
                throw ApiException.notFound("Lista não encontrada");
            }
        }
        return detail(list);
    }

    @Transactional
    public ListDetailDto update(UUID id, Long userId, ListRequestDto dto) {
        DiveListModel list = owned(id, userId);
        if (list.getTipo() != DiveListModel.Tipo.LISTA) {
            throw ApiException.badRequest("Esta lista especial não pode ser editada");
        }
        list.setNome(dto.nome().trim());
        list.setDescricao(blankToNull(dto.descricao()));
        list.setRanked(Boolean.TRUE.equals(dto.ranked()));
        list.setUpdatedAt(LocalDateTime.now());
        return detail(repository.saveAndFlush(list));
    }

    @Transactional
    public void delete(UUID id, Long userId) {
        DiveListModel list = owned(id, userId);
        if (list.getTipo() != DiveListModel.Tipo.LISTA) {
            throw ApiException.badRequest("Esta lista especial não pode ser excluída");
        }
        repository.delete(list);
    }

    // ---------------- itens ----------------

    @Transactional
    public ListDetailDto addItem(UUID id, Long userId, AddItemDto dto) {
        return addItemTo(owned(id, userId), dto);
    }

    @Transactional
    public ListDetailDto removeItem(UUID id, UUID itemId, Long userId) {
        DiveListModel list = owned(id, userId);
        boolean removed = list.getItems().removeIf(i -> i.getId().equals(itemId));
        if (!removed) {
            throw ApiException.notFound("Item não encontrado");
        }
        renumber(list);
        return detail(repository.saveAndFlush(list));
    }

    @Transactional
    public ListDetailDto reorder(UUID id, Long userId, ReorderDto dto) {
        DiveListModel list = owned(id, userId);

        Set<UUID> current = new HashSet<>();
        list.getItems().forEach(i -> current.add(i.getId()));
        if (dto.itemIds().size() != current.size() || !current.equals(new HashSet<>(dto.itemIds()))) {
            throw ApiException.badRequest("A nova ordem deve conter exatamente os itens da lista");
        }

        for (int pos = 0; pos < dto.itemIds().size(); pos++) {
            UUID itemId = dto.itemIds().get(pos);
            final int position = pos + 1;
            list.getItems().stream()
                    .filter(i -> i.getId().equals(itemId))
                    .findFirst()
                    .ifPresent(i -> i.setPosition(position));
        }
        list.getItems().sort((a, b) -> Integer.compare(a.getPosition(), b.getPosition()));
        list.setUpdatedAt(LocalDateTime.now());
        return detail(repository.saveAndFlush(list));
    }

    // ---------------- listas especiais: Quero mergulhar / Já mergulhei ----------------

    @Transactional
    public ListDetailDto wishlist(Long userId) {
        return detail(special(userId, DiveListModel.Tipo.QUERO_MERGULHAR, "Quero mergulhar"));
    }

    @Transactional
    public ListDetailDto addToWishlist(Long userId, AddItemDto dto) {
        return addItemTo(special(userId, DiveListModel.Tipo.QUERO_MERGULHAR, "Quero mergulhar"), dto);
    }

    @Transactional
    public ListDetailDto removeFromWishlist(Long userId, UUID siteId) {
        return removeSite(special(userId, DiveListModel.Tipo.QUERO_MERGULHAR, "Quero mergulhar"), siteId);
    }

    @Transactional
    public ListDetailDto visited(Long userId) {
        return detail(special(userId, DiveListModel.Tipo.JA_MERGULHEI, "Já mergulhei"));
    }

    /** Marcar "Já mergulhei" manualmente também tira o local de "Quero mergulhar". */
    @Transactional
    public ListDetailDto addToVisited(Long userId, AddItemDto dto) {
        ListDetailDto result = addItemTo(special(userId, DiveListModel.Tipo.JA_MERGULHEI, "Já mergulhei"), dto);
        removeFromWishlistQuiet(userId, dto.siteId());
        return result;
    }

    /**
     * Chamado ao registrar um mergulho: o local passa a constar em "Já mergulhei" e, se estava em
     * "Quero mergulhar", sai de lá. Idempotente.
     */
    @Transactional
    public void markVisitedFromDive(Long userId, UUID siteId) {
        DiveListModel visited = special(userId, DiveListModel.Tipo.JA_MERGULHEI, "Já mergulhei");
        boolean already = visited.getItems().stream().anyMatch(i -> i.getDiveSite().getId().equals(siteId));
        if (!already) {
            DiveSiteModel site = siteRepository.findById(siteId).orElse(null);
            if (site != null) {
                DiveListItemModel item = new DiveListItemModel();
                item.setList(visited);
                item.setDiveSite(site);
                item.setPosition(visited.getItems().size() + 1);
                visited.getItems().add(item);
                visited.setUpdatedAt(LocalDateTime.now());
                repository.saveAndFlush(visited);
            }
        }
        removeFromWishlistQuiet(userId, siteId);
    }

    private void removeFromWishlistQuiet(Long userId, UUID siteId) {
        repository.findByOwnerIdAndTipo(userId, DiveListModel.Tipo.QUERO_MERGULHAR).ifPresent(w -> {
            if (w.getItems().removeIf(i -> i.getDiveSite().getId().equals(siteId))) {
                renumber(w);
                repository.saveAndFlush(w);
            }
        });
    }

    @Transactional
    public ListDetailDto removeFromVisited(Long userId, UUID siteId) {
        return removeSite(special(userId, DiveListModel.Tipo.JA_MERGULHEI, "Já mergulhei"), siteId);
    }

    // ---------------- 4 favoritos ----------------

    @Transactional
    public ListDetailDto favorites(Long userId) {
        return detail(special(userId, DiveListModel.Tipo.FAVORITOS, "Meus 4 favoritos"));
    }

    /** Qualquer usuário autenticado vê os favoritos de um perfil. Não cria a lista se ela não existir. */
    @Transactional(readOnly = true)
    public ListDetailDto favoritesOf(Long ownerId) {
        user(ownerId);
        return repository.findByOwnerIdAndTipo(ownerId, DiveListModel.Tipo.FAVORITOS)
                .map(this::detail)
                .orElseGet(() -> new ListDetailDto(null, "Meus 4 favoritos", null, true,
                        DiveListModel.Tipo.FAVORITOS.name(), List.of()));
    }

    /** Substitui os favoritos pela lista informada (na ordem recebida, até 4). */
    @Transactional
    public ListDetailDto setFavorites(Long userId, List<UUID> siteIds) {
        if (siteIds.size() > MAX_FAVORITES) {
            throw ApiException.badRequest("Escolha até " + MAX_FAVORITES + " locais favoritos");
        }
        if (new HashSet<>(siteIds).size() != siteIds.size()) {
            throw ApiException.badRequest("Há locais repetidos nos favoritos");
        }

        DiveListModel list = special(userId, DiveListModel.Tipo.FAVORITOS, "Meus 4 favoritos");
        list.setRanked(true);

        // remove os que saíram
        list.getItems().removeIf(i -> !siteIds.contains(i.getDiveSite().getId()));
        repository.flush();

        // atualiza posição dos que ficaram e adiciona os novos (sem remover+reinserir o mesmo local,
        // para não violar a restrição de unicidade lista+local dentro do mesmo flush)
        Map<UUID, DiveListItemModel> existing = new HashMap<>();
        list.getItems().forEach(i -> existing.put(i.getDiveSite().getId(), i));

        for (int pos = 0; pos < siteIds.size(); pos++) {
            UUID siteId = siteIds.get(pos);
            DiveListItemModel item = existing.get(siteId);
            if (item == null) {
                DiveSiteModel site = siteRepository.findById(siteId)
                        .orElseThrow(() -> ApiException.notFound("Dive site não encontrado"));
                if (!site.isAtivo()) {
                    throw ApiException.badRequest("O local \"" + site.getNome() + "\" está desativado");
                }
                item = new DiveListItemModel();
                item.setList(list);
                item.setDiveSite(site);
                list.getItems().add(item);
            }
            item.setPosition(pos + 1);
        }
        list.getItems().sort((a, b) -> Integer.compare(a.getPosition(), b.getPosition()));
        list.setUpdatedAt(LocalDateTime.now());
        return detail(repository.saveAndFlush(list));
    }

    // ---------------- util ----------------

    private ListDetailDto removeSite(DiveListModel list, UUID siteId) {
        list.getItems().removeIf(i -> i.getDiveSite().getId().equals(siteId));
        renumber(list);
        return detail(repository.saveAndFlush(list));
    }

    private ListDetailDto addItemTo(DiveListModel list, AddItemDto dto) {
        DiveSiteModel site = siteRepository.findById(dto.siteId())
                .orElseThrow(() -> ApiException.notFound("Dive site não encontrado"));
        if (!site.isAtivo()) {
            throw ApiException.badRequest("Este Dive Site está desativado");
        }
        if (list.getItems().stream().anyMatch(i -> i.getDiveSite().getId().equals(site.getId()))) {
            throw ApiException.conflict("Este local já está na lista");
        }
        if (list.getTipo() == DiveListModel.Tipo.FAVORITOS && list.getItems().size() >= MAX_FAVORITES) {
            throw ApiException.badRequest("Escolha até " + MAX_FAVORITES + " locais favoritos");
        }
        if (list.getItems().size() >= MAX_ITEMS_PER_LIST) {
            throw ApiException.badRequest("Limite de " + MAX_ITEMS_PER_LIST + " locais por lista");
        }

        DiveListItemModel item = new DiveListItemModel();
        item.setList(list);
        item.setDiveSite(site);
        item.setPosition(list.getItems().size() + 1);
        item.setNota(blankToNull(dto.nota()));
        list.getItems().add(item);
        list.setUpdatedAt(LocalDateTime.now());

        return detail(repository.saveAndFlush(list));
    }

    private DiveListModel special(Long userId, DiveListModel.Tipo tipo, String nome) {
        return repository.findByOwnerIdAndTipo(userId, tipo)
                .orElseGet(() -> {
                    DiveListModel list = new DiveListModel();
                    list.setOwner(user(userId));
                    list.setNome(nome);
                    list.setTipo(tipo);
                    list.setRanked(tipo == DiveListModel.Tipo.FAVORITOS);
                    return repository.saveAndFlush(list);
                });
    }

    private DiveListModel owned(UUID id, Long userId) {
        DiveListModel list = repository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Lista não encontrada"));
        if (!list.getOwner().getId().equals(userId)) {
            throw ApiException.notFound("Lista não encontrada");
        }
        return list;
    }

    private UserModel user(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> ApiException.notFound("Usuário não encontrado"));
    }

    private static void renumber(DiveListModel list) {
        for (int i = 0; i < list.getItems().size(); i++) {
            list.getItems().get(i).setPosition(i + 1);
        }
    }

    private ListSummaryDto summary(DiveListModel l) {
        DiveSiteImageModel cover = l.getItems().stream()
                .map(i -> i.getDiveSite().getImages())
                .filter(imgs -> !imgs.isEmpty())
                .map(imgs -> imgs.get(0))
                .findFirst()
                .orElse(null);

        return new ListSummaryDto(
                l.getId(), l.getNome(), l.getDescricao(), l.isRanked(), l.getTipo().name(),
                l.getItems().size(),
                cover == null ? null : storage.urlFor(cover.getStorageKey()),
                cover == null ? null : cover.getId().toString());
    }

    private ListDetailDto detail(DiveListModel l) {
        List<ListItemDto> items = l.getItems().stream().map(i -> {
            DiveSiteModel s = i.getDiveSite();
            DiveSiteImageModel cover = s.getImages().isEmpty() ? null : s.getImages().get(0);
            String localizacao = java.util.stream.Stream.of(s.getCidade(), s.getEstado(), s.getPais())
                    .filter(v -> v != null && !v.isBlank())
                    .collect(java.util.stream.Collectors.joining(", "));
            return new ListItemDto(
                    i.getId(), i.getPosition(), i.getNota(),
                    s.getId(), s.getNome(), localizacao,
                    s.getTipo() == null ? null : s.getTipo().name(),
                    s.isAtivo(),
                    cover == null ? null : storage.urlFor(cover.getStorageKey()),
                    cover == null ? null : cover.getId().toString());
        }).toList();

        return new ListDetailDto(l.getId(), l.getNome(), l.getDescricao(), l.isRanked(), l.getTipo().name(), items);
    }

    private static String blankToNull(String v) {
        return v == null || v.isBlank() ? null : v.trim();
    }
}
