/// O que o plano do usuário permite (vem do backend em GET /api/me).
/// A regra real é aplicada no servidor; aqui só refletimos na interface.
class Entitlements {
  final String plano; // FREE | PREMIUM (plano efetivo)
  final int? maxDiveLogs; // null = ilimitado
  final int diveLogsUsed;
  final int maxPhotosPerLog;
  final bool advancedStats;
  final bool exportEnabled;

  const Entitlements({
    required this.plano,
    required this.maxDiveLogs,
    required this.diveLogsUsed,
    required this.maxPhotosPerLog,
    required this.advancedStats,
    required this.exportEnabled,
  });

  /// Valores conservadores usados antes de o servidor responder (ou offline).
  static const Entitlements free = Entitlements(
    plano: 'FREE',
    maxDiveLogs: 30,
    diveLogsUsed: 0,
    maxPhotosPerLog: 3,
    advancedStats: false,
    exportEnabled: false,
  );

  bool get isPremium => plano == 'PREMIUM';

  bool get canCreateDiveLog => maxDiveLogs == null || diveLogsUsed < maxDiveLogs!;

  int? get remainingDiveLogs =>
      maxDiveLogs == null ? null : (maxDiveLogs! - diveLogsUsed).clamp(0, maxDiveLogs!);

  factory Entitlements.fromJson(Map<String, dynamic> json) => Entitlements(
        plano: json['plano']?.toString() ?? 'FREE',
        maxDiveLogs: (json['maxDiveLogs'] as num?)?.toInt(),
        diveLogsUsed: (json['diveLogsUsed'] as num?)?.toInt() ?? 0,
        maxPhotosPerLog: (json['maxPhotosPerLog'] as num?)?.toInt() ?? 3,
        advancedStats: json['advancedStats'] as bool? ?? false,
        exportEnabled: json['exportEnabled'] as bool? ?? false,
      );
}
