package com.log.diverr.diver.plans;

import com.log.diverr.diver.users.domain.UserModel;

/**
 * O que o usuário pode fazer AGORA. O app usa isso apenas para refletir bloqueios na interface;
 * a regra real é sempre aplicada no backend.
 * maxDiveLogs == null significa ilimitado.
 */
public record EntitlementsDto(
        UserModel.Plano plano,
        Integer maxDiveLogs,
        long diveLogsUsed,
        int maxPhotosPerLog,
        boolean advancedStats,
        boolean exportEnabled
) {
}
