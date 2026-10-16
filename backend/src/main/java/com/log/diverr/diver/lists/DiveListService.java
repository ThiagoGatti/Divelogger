package com.log.diverr.diver.lists;

import com.log.diverr.diver.common.ApiException;
import com.log.diverr.diver.divesites.domain.DiveSiteImageModel;
import com.log.diverr.diver.divesites.domain.DiveSiteModel;
import com.log.diverr.diver.divesites.repository.DiveSiteRepository;
import com.log.diverr.diver.lists.ListDtos.*;
import com.log.diverr.diver.storage.ImageStorageService;
import com.log.diverr.diver.users.domain.UserModel;
import com.log.diverr.diver.users.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/** Listas pessoais. Por enquanto só o dono enxerga e edita; a visibilidade social vem com o módulo de seguidores. */
@Service
public class DiveListService {

    private static final int MAX_LISTS_PER_USER = 100;
    private static final int MAX_ITEMS_PER_LIST = 500;

    private final DiveListRepository repository;
    private final DiveSiteRepository siteRepository;
    private final UserRepository userRepository;
    private final ImageStorageService storage;

    public DiveListService(
            DiveListRepository repository,
            DiveSiteRepository siteRepository,
            UserRepository userRepository,
            ImageStorageService storage
    ) {
        this.repository = repository;
        this.siteRepository = siteRepository;
        this.userRepository = userRepository;
        this.storage = storage;
    }

    // ---------------- listas ----------------

    @Transactional(readOnly = true)
    public List<ListSummaryDto> listMine(Long userId) {
        return repository.findByOwnerIdOrderByCreatedAtDesc(userId).stream()
                .filter(l -> l.getTipo() == DiveListModel.Tipo.LISTA)
                .map(this::summary)
                .toList();
    }

    @Transactional
    public ListDetailDto create(Long userId, ListRequestDto dto) {
        UserModel owner = user(userId);
        long existing = repository.findByOwnerIdOrderByCreatedAtDesc(userId).size();
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

    @Transactional(readOnly = true)
    public ListDetailDto get(UUID id, Long userId) {
        return detail(owned(id, userId));
    }

    @Transactional
    public ListDetailDto update(UUID id, Long userId, ListRequestDto dto) {
        DiveListModel list = owned(id, userId);
        if (list.getTipo() == DiveListModel.Tipo.QUERO_MERGULHAR) {
            throw ApiException.badRequest("A lista \"Quero mergulhar\" não pode ser editada");
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
        if (list.getTipo() == DiveListModel.Tipo.QUERO_MERGULHAR) {
            throw ApiException.badRequest("A lista \"Quero mergulhar\" não pode ser excluída");
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

    // ---------------- "Quero mergulhar" ----------------

    @Transactional
    public ListDetailDto wishlist(Long userId) {
        return detail(wishlistEntity(userId));
    }

    @Transactional
    public ListDetailDto addToWishlist(Long userId, AddItemDto dto) {
        return addItemTo(wishlistEntity(userId), dto);
    }

    @Transactional
    public ListDetailDto removeFromWishlist(Long userId, UUID siteId) {
        DiveListModel list = wishlistEntity(userId);
        list.getItems().removeIf(i -> i.getDiveSite().getId().equals(siteId));
        renumber(list);
        return detail(repository.saveAndFlush(list));
    }

    // ---------------- util ----------------

    private ListDetailDto addItemTo(DiveListModel list, AddItemDto dto) {
        DiveSiteModel site = siteRepository.findById(dto.siteId())
                .orElseThrow(() -> ApiException.notFound("Dive site não encontrado"));
        if (!site.isAtivo()) {
            throw ApiException.badRequest("Este Dive Site está desativado");
        }
        if (list.getItems().stream().anyMatch(i -> i.getDiveSite().getId().equals(site.getId()))) {
            throw ApiException.conflict("Este local já está na lista");
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

    private DiveListModel wishlistEntity(Long userId) {
        return repository.findByOwnerIdAndTipo(userId, DiveListModel.Tipo.QUERO_MERGULHAR)
                .orElseGet(() -> {
                    DiveListModel list = new DiveListModel();
                    list.setOwner(user(userId));
                    list.setNome("Quero mergulhar");
                    list.setTipo(DiveListModel.Tipo.QUERO_MERGULHAR);
                    list.setRanked(false);
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
                .orElseThrow(() -> ApiException.unauthorized("Usuário não encontrado"));
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
