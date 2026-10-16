package com.log.diverr.diver.lists;

import com.log.diverr.diver.users.domain.UserModel;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Lista de Dive Sites criada pelo usuário (ranqueada ou não).
 * Cada usuário também tem uma lista especial QUERO_MERGULHAR ("lista pro futuro").
 */
@Getter
@Setter
@Entity
@Table(name = "dive_lists")
public class DiveListModel {

    public enum Tipo {
        LISTA,
        QUERO_MERGULHAR
    }

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "owner_id", nullable = false)
    private UserModel owner;

    @Column(nullable = false, length = 120)
    private String nome;

    @Column(length = 500)
    private String descricao;

    /** Ranqueada: a ordem importa e o app mostra as posições (#1, #2...). */
    @Column(nullable = false)
    private boolean ranked;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Tipo tipo = Tipo.LISTA;

    private LocalDateTime createdAt = LocalDateTime.now();

    private LocalDateTime updatedAt = LocalDateTime.now();

    @OneToMany(mappedBy = "list", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("position ASC")
    private List<DiveListItemModel> items = new ArrayList<>();
}
