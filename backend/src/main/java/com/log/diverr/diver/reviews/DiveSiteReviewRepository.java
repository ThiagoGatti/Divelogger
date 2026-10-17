package com.log.diverr.diver.reviews;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DiveSiteReviewRepository extends JpaRepository<DiveSiteReviewModel, UUID> {

    List<DiveSiteReviewModel> findTop100ByDiveSiteIdOrderByCreatedAtDesc(UUID diveSiteId);

    Optional<DiveSiteReviewModel> findByDiveSiteIdAndUserId(UUID diveSiteId, Long userId);

    List<DiveSiteReviewModel> findByScoreIsNull();

    interface RatingRow {
        UUID getSiteId();

        Double getAverage();

        Long getTotal();
    }

    @Query("select r.diveSite.id as siteId, avg(r.score) as average, count(r) as total "
            + "from DiveSiteReviewModel r group by r.diveSite.id")
    List<RatingRow> aggregateAll();

    @Query("select r.diveSite.id as siteId, avg(r.score) as average, count(r) as total "
            + "from DiveSiteReviewModel r where r.diveSite.id = :siteId group by r.diveSite.id")
    Optional<RatingRow> aggregateFor(@Param("siteId") UUID siteId);
}
