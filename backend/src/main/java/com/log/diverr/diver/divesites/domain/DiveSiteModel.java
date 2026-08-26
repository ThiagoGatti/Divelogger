package com.log.diverr.diver.divesites.domain;

import com.log.diverr.diver.users.domain.UserModel;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "dive_sites")
public class DiveSiteModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String nome;

    @Column(length = 1000)
    private String descricao;

    @Column(nullable = false)
    private String pais;

    private String estado;

    private String cidade;

    @Column(nullable = false, precision = 10, scale = 7)
    private BigDecimal latitude;

    @Column(nullable = false, precision = 10, scale = 7)
    private BigDecimal longitude;

    private Double profundidadeMaxima;

    @Enumerated(EnumType.STRING)
    private TipoDiveSite tipo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by")
    private UserModel createdBy;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public DiveSiteModel() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    public enum TipoDiveSite {
        COSTEIRO,
        NAUFRAGIO,
        RECIFE,
        CAVERNA,
        PAREDE,
        PEDREIRA,
        LAGO,
        RIO,
        OUTRO
    }
}