import 'package:flutter/foundation.dart';

/// Sinais simples entre telas (ex.: mergulho criado -> atualizar lista e estatísticas).
class AppEvents {
  AppEvents._();

  static final ValueNotifier<int> diveLogsChanged = ValueNotifier<int>(0);
  static final ValueNotifier<int> diveSitesChanged = ValueNotifier<int>(0);

  static void notifyDiveLogsChanged() => diveLogsChanged.value++;
  static void notifyDiveSitesChanged() => diveSitesChanged.value++;
}
