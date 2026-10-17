package com.log.diverr.diver.social;

import com.log.diverr.diver.common.ApiException;
import com.log.diverr.diver.social.SocialDtos.UserSummaryDto;
import com.log.diverr.diver.users.domain.UserModel;
import com.log.diverr.diver.users.domain.UserStatus;
import com.log.diverr.diver.users.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Seguir / deixar de seguir e listas de seguidores.
 * Seguir é imediato. "Amigo" = eu sigo a pessoa E ela me segue de volta.
 */
@Service
public class FollowService {

    private final FollowRepository follows;
    private final UserRepository users;

    public FollowService(FollowRepository follows, UserRepository users) {
        this.follows = follows;
        this.users = users;
    }

    @Transactional
    public void follow(Long viewerId, Long targetId) {
        if (viewerId.equals(targetId)) {
            throw ApiException.badRequest("Você não pode seguir a si mesmo");
        }
        UserModel target = activeUser(targetId);
        UserModel viewer = users.findById(viewerId)
                .orElseThrow(() -> ApiException.unauthorized("Usuário não encontrado"));

        if (follows.existsByFollowerIdAndFolloweeId(viewerId, targetId)) {
            return; // idempotente
        }
        FollowModel f = new FollowModel();
        f.setFollower(viewer);
        f.setFollowee(target);
        follows.saveAndFlush(f);
    }

    @Transactional
    public void unfollow(Long viewerId, Long targetId) {
        follows.findByFollowerIdAndFolloweeId(viewerId, targetId).ifPresent(follows::delete);
        follows.flush();
    }

    public long friendsCount(Long userId) {
        return friendIds(userId).size();
    }

    /** Ids de quem [userId] segue e que também segue [userId]. */
    public Set<Long> friendIds(Long userId) {
        Set<Long> mutual = new HashSet<>(follows.followeeIds(userId));
        mutual.retainAll(new HashSet<>(follows.followerIds(userId)));
        return mutual;
    }

    @Transactional(readOnly = true)
    public List<UserSummaryDto> followers(Long userId, Long viewerId) {
        activeUser(userId);
        return summarize(users.findAllById(follows.followerIds(userId)), viewerId);
    }

    @Transactional(readOnly = true)
    public List<UserSummaryDto> following(Long userId, Long viewerId) {
        activeUser(userId);
        return summarize(users.findAllById(follows.followeeIds(userId)), viewerId);
    }

    @Transactional(readOnly = true)
    public List<UserSummaryDto> friends(Long userId, Long viewerId) {
        activeUser(userId);
        return summarize(users.findAllById(friendIds(userId)), viewerId);
    }

    @Transactional(readOnly = true)
    public List<UserSummaryDto> search(String query, Long viewerId) {
        String q = query == null ? "" : query.trim().replaceFirst("^@", "");
        if (q.length() < 2) {
            return List.of();
        }
        List<UserModel> found = users
                .findTop20ByUsernameContainingIgnoreCaseOrNomeCompletoContainingIgnoreCase(q, q)
                .stream()
                .filter(u -> !u.getId().equals(viewerId))
                .toList();
        return summarize(found, viewerId);
    }

    // ---------------- util ----------------

    public UserModel activeUser(Long id) {
        UserModel u = users.findById(id)
                .orElseThrow(() -> ApiException.notFound("Usuário não encontrado"));
        if (u.getStatus() != UserStatus.ATIVO) {
            throw ApiException.notFound("Usuário não encontrado");
        }
        return u;
    }

    private List<UserSummaryDto> summarize(Iterable<UserModel> list, Long viewerId) {
        Set<Long> viewerFollowing = new HashSet<>(follows.followeeIds(viewerId));
        Set<Long> viewerFollowers = new HashSet<>(follows.followerIds(viewerId));

        List<UserSummaryDto> out = new java.util.ArrayList<>();
        for (UserModel u : list) {
            if (u.getStatus() != UserStatus.ATIVO) {
                continue;
            }
            boolean iFollow = viewerFollowing.contains(u.getId());
            boolean followsMe = viewerFollowers.contains(u.getId());
            out.add(new UserSummaryDto(
                    u.getId(), u.getNomeCompleto(), u.getUsername(),
                    iFollow, followsMe, iFollow && followsMe));
        }
        out.sort((a, b) -> String.valueOf(a.nome()).compareToIgnoreCase(String.valueOf(b.nome())));
        return out;
    }
}
