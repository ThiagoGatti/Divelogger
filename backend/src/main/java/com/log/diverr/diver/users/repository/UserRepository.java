package com.log.diverr.diver.users.repository;

import com.log.diverr.diver.users.domain.UserModel;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserRepository extends JpaRepository<UserModel, Long> {

    Optional<UserModel> findByEmail(String email);

    Optional<UserModel> findByResetPasswordToken(String resetPasswordToken);
    boolean existsByEmail(String email);
}
