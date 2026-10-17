package com.log.diverr.diver.bootstrap;

import com.log.diverr.diver.divelogs.domain.DiveLogModel;
import com.log.diverr.diver.divelogs.repository.DiveLogRepository;
import com.log.diverr.diver.reviews.DiveSiteReviewModel;
import com.log.diverr.diver.reviews.DiveSiteReviewRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.util.List;

/** Migra as notas inteiras antigas (1..5) para as novas colunas decimais (meia estrela). Idempotente. */
@Component
@Order(3)
public class RatingsBackfill implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(RatingsBackfill.class);

    private final DiveSiteReviewRepository reviewRepository;
    private final DiveLogRepository diveLogRepository;

    public RatingsBackfill(DiveSiteReviewRepository reviewRepository, DiveLogRepository diveLogRepository) {
        this.reviewRepository = reviewRepository;
        this.diveLogRepository = diveLogRepository;
    }

    @Override
    public void run(ApplicationArguments args) {
        List<DiveSiteReviewModel> reviews = reviewRepository.findByScoreIsNull();
        for (DiveSiteReviewModel r : reviews) {
            r.setScore((double) r.getRating());
            reviewRepository.save(r);
        }

        List<DiveLogModel> logs = diveLogRepository.findByAvaliacaoIsNotNullAndNotaExperienciaIsNull();
        for (DiveLogModel l : logs) {
            l.setNotaExperiencia(l.getAvaliacao().doubleValue());
            diveLogRepository.save(l);
        }

        if (!reviews.isEmpty() || !logs.isEmpty()) {
            log.info("Notas migradas: {} avaliações de local, {} mergulhos", reviews.size(), logs.size());
        }
    }
}
