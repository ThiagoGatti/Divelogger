package com.log.diverr.diver.divelogs.domain;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "dive_log_images")
@Getter
@Setter
public class DiveLogImageModel {

    @Id
    @GeneratedValue
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "dive_log_id", nullable = false)
    private DiveLogModel diveLog;

    @Column(nullable = false)
    private String imageUrl;

    @CreationTimestamp
    private LocalDateTime createdAt;
}
