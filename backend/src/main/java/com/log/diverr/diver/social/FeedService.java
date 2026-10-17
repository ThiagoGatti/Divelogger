package com.log.diverr.diver.social;

import com.log.diverr.diver.divelogs.domain.DiveLogModel;
import com.log.diverr.diver.divelogs.dtos.DiveLogResponseDto;
import com.log.diverr.diver.divelogs.repository.DiveLogRepository;
import com.log.diverr.diver.social.SocialDtos.FeedItemDto;
import com.log.diverr.diver.social.SocialDtos.FeedPageDto;
import com.log.diverr.diver.social.SocialDtos.SocialSummaryDto;
import com.log.diverr.diver.storage.ImageStorageService;
import com.log.diverr.diver.users.domain.UserStatus;
import com.log.diverr.diver.users.repository.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Atividade de quem eu sigo. Só entram mergulhos que a privacidade do autor permite que eu veja:
 *  PRIVATE -> nunca | FRIENDS -> só se ele também me segue | FOLLOWERS e PUBLIC -> sim (eu já o sigo).
 */
@Service
public class FeedService {

    private final FollowRepository follows;
    private final UserRepository users;
    private final DiveLogRepository logs;
    private final DiveLogSocialService social;
    private final ImageStorageService storage;

    public FeedService(
            FollowRepository follows,
            UserRepository users,
            DiveLogRepository logs,
            DiveLogSocialService social,
            ImageStorageService storage
    ) {
        this.follows = follows;
        this.users = users;
        this.logs = logs;
        this.social = social;
        this.storage = storage;
    }

    @Transactional(readOnly = true)
    public FeedPageDto feed(Long viewerId, int page, int size) {
        int safeSize = Math.max(1, Math.min(size, 30));
        int safePage = Math.max(0, page);

        Set<Long> following = new HashSet<>(follows.followeeIds(viewerId));
        if (following.isEmpty()) {
            return new FeedPageDto(List.of(), false, safePage);
        }
        Set<Long> followers = new HashSet<>(follows.followerIds(viewerId));

        List<Long> allowedOwners = users.findAllById(following).stream()
                .filter(u -> u.getStatus() == UserStatus.ATIVO)
                .filter(u -> switch (u.getDiveVisibility()) {
                    case PRIVATE -> false;
                    case FRIENDS -> followers.contains(u.getId());
                    case FOLLOWERS, PUBLIC -> true;
                })
                .map(u -> u.getId())
                .toList();

        if (allowedOwners.isEmpty()) {
            return new FeedPageDto(List.of(), false, safePage);
        }

        Page<DiveLogModel> result = logs.findByUserIdIn(
                allowedOwners,
                PageRequest.of(safePage, safeSize, Sort.by(Sort.Direction.DESC, "dataHora"))
        );

        List<UUID> ids = result.getContent().stream().map(DiveLogModel::getId).toList();
        Map<UUID, SocialSummaryDto> summaries = social.summaries(ids, viewerId);

        List<FeedItemDto> items = result.getContent().stream()
                .map(l -> new FeedItemDto(
                        DiveLogResponseDto.from(l, storage),
                        summaries.get(l.getId())))
                .toList();

        return new FeedPageDto(items, result.hasNext(), safePage);
    }
}
