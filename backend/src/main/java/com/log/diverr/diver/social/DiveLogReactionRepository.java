package com.log.diverr.diver.social;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DiveLogReactionRepository extends JpaRepository<DiveLogReactionModel, UUID> {

    Optional<DiveLogReactionModel> findByDiveLogIdAndUserId(UUID diveLogId, Long userId);

    void deleteByDiveLogId(UUID diveLogId);

    interface CountRow {
        UUID getLogId();

        String getEmoji();

        Long getTotal();
    }

    @Query("select r.diveLog.id as logId, r.emoji as emoji, count(r) as total "
            + "from DiveLogReactionModel r where r.diveLog.id in :ids group by r.diveLog.id, r.emoji")
    List<CountRow> countsFor(@Param("ids") Collection<UUID> ids);

    @Query("select r from DiveLogReactionModel r where r.diveLog.id in :ids and r.user.id = :userId")
    List<DiveLogReactionModel> mineFor(@Param("ids") Collection<UUID> ids, @Param("userId") Long userId);
}
