package com.log.diverr.diver.social;

import com.log.diverr.diver.divelogs.domain.DiveLogModel;
import com.log.diverr.diver.divelogs.repository.DiveLogRepository;
import com.log.diverr.diver.lists.DiveListModel;
import com.log.diverr.diver.lists.DiveListRepository;
import com.log.diverr.diver.social.SocialDtos.PublicProfileDto;
import com.log.diverr.diver.users.domain.UserModel;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Perfil visível para qualquer usuário autenticado: nome, @usuário, bio, contadores e favoritos.
 * Os MERGULHOS só aparecem se a privacidade do dono permitir (VisibilityService).
 */
@Service
public class ProfileService {

    private final FollowService followService;
    private final FollowRepository follows;
    private final VisibilityService visibility;
    private final DiveLogRepository logs;
    private final DiveListRepository lists;

    public ProfileService(
            FollowService followService,
            FollowRepository follows,
            VisibilityService visibility,
            DiveLogRepository logs,
            DiveListRepository lists
    ) {
        this.followService = followService;
        this.follows = follows;
        this.visibility = visibility;
        this.logs = logs;
        this.lists = lists;
    }

    @Transactional(readOnly = true)
    public PublicProfileDto publicProfile(Long viewerId, Long userId) {
        UserModel u = followService.activeUser(userId);
        boolean self = viewerId.equals(userId);
        boolean iFollow = follows.existsByFollowerIdAndFolloweeId(viewerId, userId);
        boolean followsMe = follows.existsByFollowerIdAndFolloweeId(userId, viewerId);
        boolean canView = visibility.canViewDives(viewerId, u);

        Long divesCount = null;
        Integer sitesCount = null;
        if (canView) {
            List<DiveLogModel> userLogs = logs.findByUserIdOrderByDataHoraDesc(userId);
            divesCount = (long) userLogs.size();

            Set<UUID> siteIds = new HashSet<>();
            userLogs.forEach(l -> siteIds.add(l.getDiveSite().getId()));
            lists.findByOwnerIdAndTipo(userId, DiveListModel.Tipo.JA_MERGULHEI)
                    .ifPresent(v -> v.getItems().forEach(i -> siteIds.add(i.getDiveSite().getId())));
            sitesCount = siteIds.size();
        }

        return new PublicProfileDto(
                u.getId(),
                u.getNomeCompleto(),
                u.getUsername(),
                u.getBio(),
                self,
                follows.countByFolloweeId(userId),
                follows.countByFollowerId(userId),
                followService.friendsCount(userId),
                iFollow,
                followsMe,
                iFollow && followsMe,
                u.getDiveVisibility(),
                canView,
                divesCount,
                sitesCount
        );
    }
}
