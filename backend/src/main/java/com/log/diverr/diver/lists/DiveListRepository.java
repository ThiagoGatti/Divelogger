package com.log.diverr.diver.lists;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DiveListRepository extends JpaRepository<DiveListModel, UUID> {

    List<DiveListModel> findByOwnerIdOrderByCreatedAtDesc(Long ownerId);

    Optional<DiveListModel> findByOwnerIdAndTipo(Long ownerId, DiveListModel.Tipo tipo);
}
