import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/session/session.dart';
import '../../../core/ui/widgets.dart';
import '../../dive_logs/data/dive_log_model.dart';

/// Aba "Estatísticas" do perfil. Básicas para todos; avançadas somente Premium.
class StatsTab extends StatelessWidget {
  final List<DiveLogModel> logs;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;

  const StatsTab({
    super.key,
    required this.logs,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  // ------------------------------------------------------------ cálculos

  int get _totalMinutes => logs.fold(0, (sum, l) => sum + (l.duracaoMinutos ?? 0));

  Iterable<double> _nums(double? Function(DiveLogModel) f) => logs.map(f).whereType<double>();

  double? _max(Iterable<double> v) => v.isEmpty ? null : v.reduce((a, b) => a > b ? a : b);

  double? _avg(Iterable<double> v) => v.isEmpty ? null : v.reduce((a, b) => a + b) / v.length;

  int get _sitesCount => logs.map((l) => l.diveSiteId).toSet().length;

  int? get _longest {
    final d = logs.map((l) => l.duracaoMinutos).whereType<int>();
    return d.isEmpty ? null : d.reduce((a, b) => a > b ? a : b);
  }

  double? get _avgRating {
    final r = logs.map((l) => l.notaExperiencia).whereType<double>().where((v) => v > 0);
    return r.isEmpty ? null : r.reduce((a, b) => a + b) / r.length;
  }

  double? get _avgConsumo {
    final c = logs.map((l) => l.consumoBar).whereType<int>().map((v) => v.toDouble());
    return _avg(c);
  }

  String? get _topGas {
    final counts = <String, int>{};
    for (final l in logs) {
      if (l.tipoGas != null) counts[l.tipoGas!] = (counts[l.tipoGas!] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return labelOf(kGasLabels, top.key);
  }

  List<(String, int)> get _byMonth {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i));
      final count = logs.where((l) => l.dataHora.year == d.year && l.dataHora.month == d.month).length;
      return (kMonthsShort[d.month - 1], count);
    });
  }

  List<(String, int)> get _byYear {
    final counts = <int, int>{};
    for (final l in logs) {
      counts[l.dataHora.year] = (counts[l.dataHora.year] ?? 0) + 1;
    }
    final years = counts.keys.toList()..sort((a, b) => b.compareTo(a));
    return years.take(5).map((y) => ('$y', counts[y]!)).toList();
  }

  List<(String, int)> get _topSites {
    final counts = <String, int>{};
    for (final l in logs) {
      counts[l.diveSiteNome] = (counts[l.diveSiteNome] ?? 0) + 1;
    }
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).map((e) => (e.key, e.value)).toList();
  }

  // ------------------------------------------------------------ UI

  Widget _locked(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: DiverrTheme.gold.withOpacity(.16), shape: BoxShape.circle),
              child: const Icon(Icons.lock_outline, color: DiverrTheme.gold),
            ),
            const SizedBox(height: 14),
            const Text('Estatísticas avançadas', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 8),
            const Text(
              'Profundidade média, mergulho mais longo, consumo médio, temperatura e visibilidade médias, '
              'mergulhos por mês e por ano, locais favoritos e mais.',
              textAlign: TextAlign.center,
              style: TextStyle(color: DiverrTheme.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => showUpgradeSheet(context),
              icon: const Icon(Icons.workspace_premium),
              label: const Text('Conhecer o Premium'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bars(String title, List<(String, int)> data) {
    final maxCount = data.map((m) => m.$2).fold(1, (a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final m in data)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${m.$2}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                          const SizedBox(height: 4),
                          Container(
                            height: 8 + 80.0 * (m.$2 / maxCount),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [DiverrTheme.primary, DiverrTheme.secondary],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(m.$1, style: const TextStyle(fontSize: 12, color: DiverrTheme.muted)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _advanced() {
    final top = _topSites;
    final years = _byYear;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 128,
          ),
          children: [
            StatCard(icon: Icons.swap_vert, value: formatMeters(_avg(_nums((l) => l.profundidadeMaxima))), label: 'Prof. média'),
            StatCard(icon: Icons.hourglass_bottom, value: formatDuration(_longest), label: 'Mergulho mais longo'),
            StatCard(icon: Icons.thermostat_outlined, value: formatNumber(_avg(_nums((l) => l.temperaturaAgua)), '°C'), label: 'Temp. média'),
            StatCard(icon: Icons.visibility_outlined, value: formatMeters(_avg(_nums((l) => l.visibilidade))), label: 'Visibilidade média'),
            StatCard(icon: Icons.speed, value: formatNumber(_avgConsumo, 'bar'), label: 'Consumo médio'),
            StatCard(icon: Icons.star_rounded, value: _avgRating == null ? '—' : _avgRating!.toStringAsFixed(1), label: 'Experiência média'),
          ],
        ),
        if (_topGas != null) ...[
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.air, color: DiverrTheme.primary),
              title: const Text('Mistura mais usada', style: TextStyle(fontWeight: FontWeight.w700)),
              trailing: Text(_topGas!, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _bars('Mergulhos por mês', _byMonth),
        if (years.length > 1) ...[
          const SizedBox(height: 12),
          _bars('Mergulhos por ano', years.reversed.toList()),
        ],
        if (top.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Locais favoritos', style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  for (var i = 0; i < top.length; i++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: DiverrTheme.ocean.withOpacity(.35),
                        child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w900, color: DiverrTheme.primary)),
                      ),
                      title: Text(top[i].$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                      trailing: Text('${top[i].$2}x', style: const TextStyle(fontWeight: FontWeight.w800, color: DiverrTheme.muted)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          if (loading)
            const SkeletonList(count: 3, height: 110)
          else if (error != null && logs.isEmpty)
            ErrorState(message: error!, onRetry: onRefresh)
          else if (logs.isEmpty)
            const EmptyState(
              icon: Icons.bar_chart_rounded,
              title: 'Sem dados ainda',
              message: 'Registre seus mergulhos para ver estatísticas e acompanhar sua evolução.',
            )
          else ...[
            GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 128,
          ),
          children: [
                StatCard(icon: Icons.scuba_diving, value: '${logs.length}', label: 'Mergulhos'),
                StatCard(icon: Icons.timer_outlined, value: formatDuration(_totalMinutes), label: 'Tempo submerso'),
                StatCard(icon: Icons.arrow_downward, value: formatMeters(_max(_nums((l) => l.profundidadeMaxima))), label: 'Prof. máxima'),
                StatCard(icon: Icons.place_outlined, value: '$_sitesCount', label: 'Locais visitados'),
              ],
            ),
            const SectionTitle('Avançadas'),
            ValueListenableBuilder<int>(
              valueListenable: AppSession.instance.changed,
              builder: (context, _, __) =>
                  AppSession.instance.entitlements.advancedStats ? _advanced() : _locked(context),
            ),
          ],
        ],
      ),
    );
  }
}
