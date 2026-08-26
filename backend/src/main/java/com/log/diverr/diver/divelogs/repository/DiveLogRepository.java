package com.log.diverr.diver.divelogs.repository;

import com.log.diverr.diver.divelogs.domain.DiveLogModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface DiveLogRepository extends JpaRepository<DiveLogModel, UUID> {

    List<DiveLogModel> findByUserId(Long userId);

    List<DiveLogModel> findByDiveSiteId(UUID diveSiteId);
}