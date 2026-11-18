package com.log.diverr.diver.users.domain;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import com.fasterxml.jackson.annotation.JsonIgnore;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;
import com.log.diverr.diver.users.domain.Role;

@Getter
@Setter
@Entity
@Table(name = "users")
public class UserModel {

        @Id
        @GeneratedValue(strategy = GenerationType.IDENTITY)
        private Long id;

        private String nomeCompleto;

        @Column(unique = true, nullable = false)
        private String email;

        private String telefone;

        @JsonIgnore
        private String senha;
        private LocalDate dataNascimento;
        private boolean verificado;
        private boolean aceitouTermosUso;
        private boolean aceitouPoliticaPrivacidade;

        @Enumerated(EnumType.STRING)
        private UserStatus status;
        @Enumerated(EnumType.STRING)
        private Plano plano;

        @Column(name = "plan_expires_at")
        @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd")
        private LocalDate planExpiresAt;

        @Enumerated(EnumType.STRING)
        @Column(nullable = false, length = 20)
        private Role role = Role.USER;

        private LocalDateTime createdAt;
        private LocalDateTime updatedAt;

        private String resetPasswordToken;
        private LocalDateTime resetPasswordTokenExpiresAt;
        private String profileImageUrl;

        /** Identificador público (@usuario). Único; gerado automaticamente no cadastro. */
        @Column(unique = true, length = 30)
        private String username;

        @Column(length = 300)
        private String bio;

        /** Identificador da conta Google (claim "sub"), quando o usuário entrou/vinculou com o Google. */
        @Column(unique = true, length = 64)
        private String googleSub;

        /** Chave da foto de perfil no S3. */
        @Column(length = 300)
        private String profilePhotoKey;

        /** Tentativas erradas do código de recuperação de senha (zera a cada novo código). */
        private Integer resetAttempts;

        /** Quem pode ver os mergulhos. Linhas antigas (null) valem FOLLOWERS. */
        @Enumerated(EnumType.STRING)
        @Column(length = 20)
        private DiveVisibility diveVisibility = DiveVisibility.FOLLOWERS;

        public DiveVisibility getDiveVisibility() {
            return diveVisibility == null ? DiveVisibility.FOLLOWERS : diveVisibility;
        }

        public enum Plano {
            FREE, PREMIUM,
        }

        public UserModel() {
            this.createdAt = LocalDateTime.now();
            this.updatedAt = LocalDateTime.now();
            this.status = UserStatus.ATIVO;
            this.verificado = false;
            this.plano = Plano.FREE;
            this.role = Role.USER;


        }

    }

