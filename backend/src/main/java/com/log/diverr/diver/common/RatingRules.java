package com.log.diverr.diver.common;

/** Notas de 0,5 a 5 estrelas, em passos de meia estrela. */
public final class RatingRules {

    private RatingRules() {}

    public static void assertHalfStep(Double value, String label) {
        if (value == null) {
            return;
        }
        boolean outOfRange = value < 0.5 || value > 5.0;
        boolean notHalfStep = Math.abs(value * 2 - Math.round(value * 2)) > 1e-9;
        if (outOfRange || notHalfStep) {
            throw ApiException.badRequest(label + " deve ir de 0,5 a 5 estrelas, em passos de meia estrela");
        }
    }

    /** Valor inteiro (1..5) para a coluna legada, que continua NOT NULL. */
    public static int legacy(double value) {
        return (int) Math.max(1, Math.min(5, Math.round(value)));
    }
}
