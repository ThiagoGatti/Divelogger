package com.log.diverr.diver.users.domain;

/** Quem pode ver os mergulhos do usuário. Padrão: FOLLOWERS (só seguidores). */
public enum DiveVisibility {
    PRIVATE,    // só o próprio usuário
    FOLLOWERS,  // quem o segue
    PUBLIC      // qualquer usuário do app
}
