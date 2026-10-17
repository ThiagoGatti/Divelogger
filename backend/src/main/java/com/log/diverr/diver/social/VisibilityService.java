package com.log.diverr.diver.social;

import com.log.diverr.diver.users.domain.UserModel;
import org.springframework.stereotype.Service;

/**
 * Regra ÚNICA de quem pode ver os mergulhos (e listas) de um usuário.
 * Todo endpoint que expõe dados de outra pessoa passa por aqui.
 *
 *  PRIVATE   -> só o dono
 *  FRIENDS   -> seguimento mútuo
 *  FOLLOWERS -> quem o segue
 *  PUBLIC    -> qualquer usuário autenticado
 */
@Service
public class VisibilityService {

    private final FollowRepository follows;

    public VisibilityService(FollowRepository follows) {
        this.follows = follows;
    }

    public boolean canViewDives(Long viewerId, UserModel owner) {
        if (viewerId.equals(owner.getId())) {
            return true;
        }
        return switch (owner.getDiveVisibility()) {
            case PRIVATE -> false;
            case PUBLIC -> true;
            case FOLLOWERS -> follows.existsByFollowerIdAndFolloweeId(viewerId, owner.getId());
            case FRIENDS -> follows.existsByFollowerIdAndFolloweeId(viewerId, owner.getId())
                    && follows.existsByFollowerIdAndFolloweeId(owner.getId(), viewerId);
        };
    }
}
