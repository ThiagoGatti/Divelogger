package com.log.diverr.diver.operators;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface OperatorRepository extends JpaRepository<OperatorModel, UUID> {

    List<OperatorModel> findByAtivoTrueOrderByNomeAsc();

    List<OperatorModel> findAllByOrderByNomeAsc();
}
