package com.log.diverr.diver.social;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface FollowRepository extends JpaRepository<FollowModel, UUID> {

    boolean existsByFollowerIdAndFolloweeId(Long followerId, Long followeeId);

    Optional<FollowModel> findByFollowerIdAndFolloweeId(Long followerId, Long followeeId);

    long countByFolloweeId(Long followeeId);

    long countByFollowerId(Long followerId);

    /** Ids de quem [userId] segue. */
    @Query("select f.followee.id from FollowModel f where f.follower.id = :userId")
    List<Long> followeeIds(@Param("userId") Long userId);

    /** Ids de quem segue [userId]. */
    @Query("select f.follower.id from FollowModel f where f.followee.id = :userId")
    List<Long> followerIds(@Param("userId") Long userId);
}
