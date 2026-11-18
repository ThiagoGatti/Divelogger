import 'package:flutter/material.dart';

import 'offline/local_store.dart';

/// Preferência de tema: Sistema (padrão), Claro ou Escuro. Guardada no aparelho.
class ThemeController {
  ThemeController._();

  static final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(ThemeMode.system);

  static Future<void> load() async {
    final raw = await LocalStore.readJson('settings.json');
    final v = raw is Map ? raw['themeMode'] : null;
    mode.value = v == 'light'
        ? ThemeMode.light
        : v == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system;
  }

  static Future<void> set(ThemeMode m) async {
    mode.value = m;
    await LocalStore.writeJson('settings.json', {
      'themeMode': m == ThemeMode.light
          ? 'light'
          : m == ThemeMode.dark
              ? 'dark'
              : 'system',
    });
  }
}
