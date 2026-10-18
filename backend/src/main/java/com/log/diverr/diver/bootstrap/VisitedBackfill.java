package com.log.diverr.diver.bootstrap;

import com.log.diverr.diver.divelogs.domain.DiveLogModel;
import com.log.diverr.diver.divelogs.repository.DiveLogRepository;
import com.log.diverr.diver.lists.DiveListService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

/** Todo local onde o usuário já tem mergulho registrado passa a constar em "Já mergulhei". Idempotente. */
@Component
@Order(4)
public class VisitedBackfill implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(VisitedBackfill.class);

    private final DiveLogRepository diveLogs;
    private final DiveListService lists;

    public VisitedBackfill(DiveLogRepository diveLogs, DiveListService lists) {
        this.diveLogs = diveLogs;
        this.lists = lists;
    }

    @Override
    public void run(ApplicationArguments args) {
        try {
            Set<String> done = new HashSet<>();
            int count = 0;
            for (DiveLogModel l : diveLogs.findAll()) {
                Long userId = l.getUser().getId();
                UUID siteId = l.getDiveSite().getId();
                if (done.add(userId + ":" + siteId)) {
                    lists.markVisitedFromDive(userId, siteId);
                    count++;
                }
            }
            if (count > 0) {
                log.info("\"Já mergulhei\" sincronizado para {} par(es) usuário/local", count);
            }
        } catch (Exception e) {
            log.warn("VisitedBackfill ignorado: {}", e.getMessage());
        }
    }
}
