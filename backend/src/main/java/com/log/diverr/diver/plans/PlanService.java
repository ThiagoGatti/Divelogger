package com.log.diverr.diver.plans;

import com.log.diverr.diver.users.domain.Role;
import com.log.diverr.diver.users.domain.UserModel;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDate;

/**
 * Definição dos planos (ajustável em application.properties):
 *
 *  FREE     -> mergulhos ILIMITADOS, até 2 fotos por mergulho, 2 fotos por Dive Site,
 *              informações básicas dos locais, estatísticas básicas
 *  PREMIUM  -> tudo do Free + até 10 fotos por mergulho, todas as fotos e informações
 *              avançadas dos locais (inseridas pelos admins), estatísticas avançadas
 *
 * ADMIN enxerga tudo (precisa para cadastrar e editar os locais).
 * PREMIUM com planExpiresAt vencido é tratado como FREE.
 */
@Service
public class PlanService {

    private static final int UNLIMITED_PHOTOS = 100;

    private final int freeMaxPhotosPerLog;
    private final int premiumMaxPhotosPerLog;
    private final int freeMaxSitePhotos;

    public PlanService(
            @Value("${app.plans.free.max-photos-per-log:2}") int freeMaxPhotosPerLog,
            @Value("${app.plans.premium.max-photos-per-log:10}") int premiumMaxPhotosPerLog,
            @Value("${app.plans.free.max-site-photos:2}") int freeMaxSitePhotos
    ) {
        this.freeMaxPhotosPerLog = freeMaxPhotosPerLog;
        this.premiumMaxPhotosPerLog = premiumMaxPhotosPerLog;
        this.freeMaxSitePhotos = freeMaxSitePhotos;
    }

    public boolean isPremium(UserModel user) {
        if (user.getPlano() != UserModel.Plano.PREMIUM) {
            return false;
        }
        LocalDate expires = user.getPlanExpiresAt();
        return expires == null || !expires.isBefore(LocalDate.now());
    }

    public UserModel.Plano effectivePlan(UserModel user) {
        return isPremium(user) ? UserModel.Plano.PREMIUM : UserModel.Plano.FREE;
    }

    /** Mergulhos são ilimitados em todos os planos (null = sem limite; campo mantido por compatibilidade). */
    public Integer maxDiveLogs(UserModel user) {
        return null;
    }

    public int maxPhotosPerLog(UserModel user) {
        return isPremium(user) ? premiumMaxPhotosPerLog : freeMaxPhotosPerLog;
    }

    /** Informações avançadas dos Dive Sites: Premium e ADMIN. */
    public boolean canSeeExtendedSiteInfo(UserModel user) {
        return isPremium(user) || user.getRole() == Role.ADMIN;
    }

    /** Quantas fotos de cada Dive Site o usuário enxerga. */
    public int maxSitePhotosVisible(UserModel user) {
        return canSeeExtendedSiteInfo(user) ? UNLIMITED_PHOTOS : freeMaxSitePhotos;
    }

    public EntitlementsDto entitlementsFor(UserModel user, long diveLogsUsed) {
        boolean premium = isPremium(user);
        return new EntitlementsDto(
                effectivePlan(user),
                null,
                diveLogsUsed,
                maxPhotosPerLog(user),
                maxSitePhotosVisible(user),
                canSeeExtendedSiteInfo(user),
                premium,
                premium
        );
    }

    public void assertCanAddPhoto(UserModel user, int currentPhotos) {
        int max = maxPhotosPerLog(user);
        if (currentPhotos >= max) {
            throw com.log.diverr.diver.common.ApiException.planLimit(
                    "Limite de " + max + " fotos por mergulho no seu plano."
                            + (isPremium(user) ? "" : " Faça upgrade para o Premium para adicionar mais."));
        }
    }
}
