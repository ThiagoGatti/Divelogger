package com.log.diverr.diver.plans;

import com.log.diverr.diver.common.ApiException;
import com.log.diverr.diver.users.domain.UserModel;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDate;

/**
 * Definição dos planos (ajustável em application.properties):
 *
 *  FREE     -> até N mergulhos, até 3 fotos por mergulho, estatísticas básicas
 *  PREMIUM  -> mergulhos ilimitados, até 10 fotos por mergulho, estatísticas avançadas, exportação
 *
 * PREMIUM com planExpiresAt vencido é tratado como FREE.
 */
@Service
public class PlanService {

    private final int freeMaxDiveLogs;
    private final int freeMaxPhotos;
    private final int premiumMaxPhotos;

    public PlanService(
            @Value("${app.plans.free.max-dive-logs:30}") int freeMaxDiveLogs,
            @Value("${app.plans.free.max-photos-per-log:3}") int freeMaxPhotos,
            @Value("${app.plans.premium.max-photos-per-log:10}") int premiumMaxPhotos
    ) {
        this.freeMaxDiveLogs = freeMaxDiveLogs;
        this.freeMaxPhotos = freeMaxPhotos;
        this.premiumMaxPhotos = premiumMaxPhotos;
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

    /** null = ilimitado */
    public Integer maxDiveLogs(UserModel user) {
        return isPremium(user) ? null : freeMaxDiveLogs;
    }

    public int maxPhotosPerLog(UserModel user) {
        return isPremium(user) ? premiumMaxPhotos : freeMaxPhotos;
    }

    public EntitlementsDto entitlementsFor(UserModel user, long diveLogsUsed) {
        boolean premium = isPremium(user);
        return new EntitlementsDto(
                effectivePlan(user),
                maxDiveLogs(user),
                diveLogsUsed,
                maxPhotosPerLog(user),
                premium,
                premium
        );
    }

    public void assertCanCreateDiveLog(UserModel user, long currentCount) {
        Integer max = maxDiveLogs(user);
        if (max != null && currentCount >= max) {
            throw ApiException.planLimit(
                    "Você atingiu o limite de " + max + " mergulhos do plano Free. Faça upgrade para o Premium para registrar mais.");
        }
    }

    public void assertCanAddPhoto(UserModel user, int currentPhotos) {
        int max = maxPhotosPerLog(user);
        if (currentPhotos >= max) {
            throw ApiException.planLimit(
                    "Limite de " + max + " fotos por mergulho no seu plano."
                            + (isPremium(user) ? "" : " Faça upgrade para o Premium para adicionar mais."));
        }
    }
}
