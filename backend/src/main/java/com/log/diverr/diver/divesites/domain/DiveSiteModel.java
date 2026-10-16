package com.log.diverr.diver.divesites.domain;

import com.log.diverr.diver.users.domain.UserModel;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
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

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private NivelDificuldade nivel;

    // ---- Informações avançadas (visíveis para Premium e ADMIN) ----
    @Column(length = 200)
    private String melhorEpoca;

    @Column(length = 200)
    private String visibilidadeTipica;

    @Column(length = 200)
    private String temperaturaAgua;

    @Column(length = 200)
    private String correnteTipica;

    @Column(length = 200)
    private String certificacaoMinima;

    @Column(length = 2000)
    private String faunaFlora;

    @Column(length = 2000)
    private String comoChegar;

    @Column(length = 2000)
    private String infraestrutura;

    @Column(length = 2000)
    private String dicas;

    @Column(length = 2000)
    private String avisosSeguranca;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by")
    private UserModel createdBy;

    /** Desativação lógica: locais inativos somem para usuários comuns, mas os mergulhos antigos continuam válidos. */
    @Column(nullable = false, columnDefinition = "boolean default true")
    private boolean ativo = true;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @OneToMany(
            mappedBy = "diveSite",
            cascade = CascadeType.ALL,
            orphanRemoval = true
    )
    private List<DiveSiteImageModel> images = new ArrayList<>();


    public DiveSiteModel() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    public boolean hasExtendedInfo() {
        return notBlank(melhorEpoca) || notBlank(visibilidadeTipica) || notBlank(temperaturaAgua)
                || notBlank(correnteTipica) || notBlank(certificacaoMinima) || notBlank(faunaFlora)
                || notBlank(comoChegar) || notBlank(infraestrutura) || notBlank(dicas)
                || notBlank(avisosSeguranca);
    }

    private static boolean notBlank(String v) {
        return v != null && !v.isBlank();
    }

    public enum NivelDificuldade {
        INICIANTE,
        INTERMEDIARIO,
        AVANCADO,
        TECNICO
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