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

    @Column(nullable = false)
    private String imageUrl;

    @CreationTimestamp
    private LocalDateTime createdAt;
}