package com.log.diverr.diver.divelogs.domain;

import com.log.diverr.diver.divesites.domain.DiveSiteModel;
import com.log.diverr.diver.users.domain.UserModel;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "dive_logs")
public class DiveLogModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private UserModel user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "dive_site_id", nullable = false)
    private DiveSiteModel diveSite;

    @Column(nullable = false)
    private LocalDateTime dataHora;

    private Integer duracaoMinutos;

    private Double profundidadeMaxima;

    private Double profundidadeMedia;

    private Double visibilidade;

    private Double temperaturaAgua;

    @Enumerated(EnumType.STRING)
    private TipoCorrente corrente;

    @Enumerated(EnumType.STRING)
    private TipoAgua tipoAgua;

    @Enumerated(EnumType.STRING)
    private TipoEntrada tipoEntrada;

    @Enumerated(EnumType.STRING)
    private TipoGas tipoGas;

    private Integer pressaoInicial;

    private Integer pressaoFinal;

    private Integer avaliacao;

    @Column(length = 3000)
    private String observacoes;

    @CreationTimestamp
    private LocalDateTime createdAt;
    @UpdateTimestamp
    private LocalDateTime updatedAt;
    @OneToMany(
            mappedBy = "diveLog",
            cascade = CascadeType.ALL,
            orphanRemoval = true
    )
    private List<DiveLogImageModel> images = new ArrayList<>();

    public enum TipoCorrente {
        NENHUMA,
        FRACA,
        MODERADA,
        FORTE
    }

    public enum TipoAgua {
        SALGADA,
        DOCE
    }

    public enum TipoEntrada {
        PRAIA,
        BARCO,
        COSTA,
        PIER,
        PISCINA,
        OUTRO
    }

    public enum TipoGas {
        AR,
        NITROX,
        TRIMIX,
        OUTRO
    }
}