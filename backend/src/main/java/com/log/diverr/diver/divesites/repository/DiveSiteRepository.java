package com.log.diverr.diver.divesites.repository;

import com.log.diverr.diver.divesites.domain.DiveSiteModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface DiveSiteRepository extends JpaRepository<DiveSiteModel, UUID> {
}