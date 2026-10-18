package com.log.diverr.diver.bootstrap;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.List;

/**
 * Por que existe: o Hibernate cria uma restrição CHECK para cada campo @Enumerated(STRING), listando os valores
 * que existiam NAQUELE momento. Com ddl-auto=update essa restrição nunca é atualizada, então qualquer valor novo de
 * enum (ex.: JA_MERGULHEI, FAVORITOS, FRIENDS) passa a ser recusado pelo banco ("conflita com dados existentes").
 *
 * O que faz: a cada inicialização remove as CHECKs de enum das tabelas abaixo (idempotente). A validação dos valores
 * continua sendo feita pelo Java (o enum). Quando o projeto adotar migrations (Flyway), este componente sai.
 * Só atua em PostgreSQL; qualquer falha é registrada e ignorada (nunca impede o app de subir).
 */
@Component
@Order(0)
public class SchemaFixer implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(SchemaFixer.class);

    /** Tabelas com colunas @Enumerated. */
    private static final List<String> TABLES = List.of("users", "dive_sites", "dive_logs", "dive_lists");

    @PersistenceContext
    private EntityManager em;

    private final PlatformTransactionManager transactionManager;

    public SchemaFixer(PlatformTransactionManager transactionManager) {
        this.transactionManager = transactionManager;
    }

    @Override
    public void run(ApplicationArguments args) {
        try {
            new TransactionTemplate(transactionManager).executeWithoutResult(status -> {
                for (String table : TABLES) {
                    dropEnumChecks(table);
                }
            });
        } catch (Exception e) {
            log.warn("SchemaFixer ignorado: {}", e.getMessage());
        }
    }

    private void dropEnumChecks(String table) {
        List<?> names = em.createNativeQuery(
                "select c.conname from pg_constraint c "
                        + "join pg_class t on t.oid = c.conrelid "
                        + "join pg_namespace n on n.oid = t.relnamespace "
                        + "where c.contype = 'c' and t.relname = :t and n.nspname = current_schema() "
                        + "and (pg_get_constraintdef(c.oid) ilike '%ARRAY[%' "
                        + "or pg_get_constraintdef(c.oid) ilike '% in (%')")
                .setParameter("t", table)
                .getResultList();

        for (Object name : names) {
            em.createNativeQuery("alter table " + table + " drop constraint if exists \"" + name + "\"")
                    .executeUpdate();
            log.info("Restrição CHECK de enum removida: {}.{}", table, name);
        }
    }
}
