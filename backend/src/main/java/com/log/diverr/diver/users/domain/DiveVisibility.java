package com.log.diverr.diver.users.domain;

/**
 * Quem pode ver os mergulhos do usuário. Padrão: FOLLOWERS.
 * "Amigo" = seguimento mútuo (eu sigo a pessoa e ela me segue de volta).
 */
public enum DiveVisibility {
    PRIVATE,    // só o próprio usuário
    FRIENDS,    // quem ele segue E que também o segue (seguimento mútuo)
    FOLLOWERS,  // quem o segue
    PUBLIC      // qualquer usuário do app
}
