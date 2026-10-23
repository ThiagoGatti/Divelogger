package com.log.diverr.diver.operators;

import com.log.diverr.diver.divesites.domain.DiveSiteModel;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

/** Operadora de mergulho. Cadastrada por ADMIN e vinculada aos Dive Sites onde atua. */
@Getter
@Setter
@Entity
@Table(name = "dive_operators")
public class OperatorModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 150)
    private String nome;

    /** Chave do objeto no S3 (uma foto por operadora). */
    @Column(length = 300)
    private String photoKey;

    @Column(nullable = false, columnDefinition = "boolean default true")
    private boolean ativo = true;

    private LocalDateTime createdAt = LocalDateTime.now();

    private LocalDateTime updatedAt = LocalDateTime.now();

    @ManyToMany(mappedBy = "operators")
    private Set<DiveSiteModel> sites = new HashSet<>();
}
