package com.log.diverr.diver.social;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

@Repository
public interface DiveLogCommentRepository extends JpaRepository<DiveLogCommentModel, UUID> {

    List<DiveLogCommentModel> findByDiveLogIdOrderByCreatedAtAsc(UUID diveLogId);

    void deleteByDiveLogId(UUID diveLogId);

    interface CountRow {
        UUID getLogId();

        Long getTotal();
    }

    @Query("select c.diveLog.id as logId, count(c) as total "
            + "from DiveLogCommentModel c where c.diveLog.id in :ids group by c.diveLog.id")
    List<CountRow> countsFor(@Param("ids") Collection<UUID> ids);
}
