package com.log.diverr.diver.reviews;

import com.log.diverr.diver.divesites.domain.DiveSiteModel;
import com.log.diverr.diver.users.domain.UserModel;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

/** Avaliação de um Dive Site: nota de 1 a 5 + comentário. Um por usuário e por local (editável). */
@Getter
@Setter
@Entity
@Table(
        name = "dive_site_reviews",
        uniqueConstraints = @UniqueConstraint(columnNames = {"dive_site_id", "user_id"})
)
public class DiveSiteReviewModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "dive_site_id", nullable = false)
    private DiveSiteModel diveSite;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private UserModel user;

    /** Legado (1..5 inteiro, NOT NULL). Mantido preenchido; a nota real é [score]. */
    @Column(nullable = false)
    private int rating;

    /** Nota de 0,5 a 5 (meia estrela). */
    private Double score;

    @Column(length = 2000)
    private String texto;

    private LocalDateTime createdAt = LocalDateTime.now();

    private LocalDateTime updatedAt = LocalDateTime.now();
}
