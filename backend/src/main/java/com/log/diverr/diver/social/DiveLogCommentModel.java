package com.log.diverr.diver.social;

import com.log.diverr.diver.divelogs.domain.DiveLogModel;
import com.log.diverr.diver.users.domain.UserModel;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "dive_log_comments")
public class DiveLogCommentModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "dive_log_id", nullable = false)
    private DiveLogModel diveLog;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private UserModel user;

    @Column(nullable = false, length = 1000)
    private String texto;

    private LocalDateTime createdAt = LocalDateTime.now();
}
