package com.log.diverr.diver.divesites.domain;

import com.log.diverr.diver.users.domain.UserModel;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "dive_site_images")
@Getter
@Setter
public class DiveSiteImageModel {

    @Id
    @GeneratedValue
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "dive_site_id", nullable = false)
    private DiveSiteModel diveSite;

    /** Chave do objeto no S3 (a coluna mantém o nome antigo para não alterar o schema). */
    @Column(name = "image_url", nullable = false)
    private String storageKey;

    @CreationTimestamp
    private LocalDateTime createdAt;
}