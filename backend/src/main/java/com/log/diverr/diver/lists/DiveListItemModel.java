package com.log.diverr.diver.lists;

import com.log.diverr.diver.divesites.domain.DiveSiteModel;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@Entity
@Table(
        name = "dive_list_items",
        uniqueConstraints = @UniqueConstraint(columnNames = {"list_id", "dive_site_id"})
)
public class DiveListItemModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "list_id", nullable = false)
    private DiveListModel list;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "dive_site_id", nullable = false)
    private DiveSiteModel diveSite;

    @Column(nullable = false)
    private int position;

    @Column(length = 500)
    private String nota;

    private LocalDateTime addedAt = LocalDateTime.now();
}
