import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/events.dart';
import '../../../core/format.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/ui/widgets.dart';
import '../../dive_logs/data/dive_log_model.dart';
import '../../dive_logs/data/dive_logs_api.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final _api = DiveLogsApi();
  List<DiveLogModel> _logs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    AppEvents.diveLogsChanged.addListener(_load);
  }

  @override
  void dispose() {
    AppEvents.diveLogsChanged.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!AppSession.instance.isLoggedIn) return;
    try {
      final logs = await _api.findMine();
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  // ------------------------------------------------------------ cálculos

  int get _totalMinutes => _logs.fold(0, (sum, l) => sum + (l.duracaoMinutos ?? 0));

  double? get _maxDepth {
    final depths = _logs.map((l) => l.profundidadeMaxima).whereType<double>();
    return depths.isEmpty ? null : depths.reduce((a, b) => a > b ? a : b);
  }

  double? get _avgDepth {
    final depths = _logs.map((l) => l.profundidadeMaxima).whereType<double>().toList();
    if (depths.isEmpty) return null;
    return depths.reduce((a, b) => a + b) / depths.length;
  }

  int get _sitesCount => _logs.map((l) => l.diveSiteId).toSet().length;

  /// (rótulo do mês, quantidade) dos últimos 6 meses
  List<(String, int)> get _byMonth {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i));
      final count = _logs.where((l) => l.dataHora.year == d.year && l.dataHora.month == d.month).length;
      return (kMonthsShort[d.month - 1], count);
    });
  }

  List<(String, int)> get _topSites {
    final counts = <String, int>{};
    for (final l in _logs) {
      counts[l.diveSiteNome] = (counts[l.diveSiteNome] ?? 0) + 1;
    }
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).map((e) => (e.key, e.value)).toList();
  }

  // ------------------------------------------------------------ UI

  Widget _advanced() {
    return ValueListenableBuilder<int>(
      valueListenable: AppSession.instance.changed,
      builder: (context, _, __) {
        final premium = AppSession.instance.entitlements.advancedStats;

        if (!premium) {
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
                  const SizedBox(height: 6),
                  const Text(
                    'Veja sua evolução mês a mês e seus locais favoritos com o plano Premium.',
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

        final months = _byMonth;
        final maxCount = months.map((m) => m.$2).fold(1, (a, b) => a > b ? a : b);
        final top = _topSites;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mergulhos por mês', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 130,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final m in months)
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
            ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = _logs.isEmpty ? null : _logs.first;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
          children: [
            const PageHeader(
              title: 'Atividade',
              subtitle: 'Acompanhe sua evolução como mergulhador.',
            ),
            if (_loading)
              const SkeletonList(count: 3, height: 110)
            else if (_error != null && _logs.isEmpty)
              ErrorState(message: _error!, onRetry: _load)
            else if (_logs.isEmpty)
              const EmptyState(
                icon: Icons.bar_chart_rounded,
                title: 'Sem dados ainda',
                message: 'Registre seus mergulhos para ver estatísticas e acompanhar sua evolução.',
              )
            else ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  StatCard(icon: Icons.scuba_diving, value: '${_logs.length}', label: 'Mergulhos'),
                  StatCard(icon: Icons.timer_outlined, value: formatDuration(_totalMinutes), label: 'Tempo submerso'),
                  StatCard(icon: Icons.arrow_downward, value: formatMeters(_maxDepth), label: 'Prof. máxima'),
                  StatCard(icon: Icons.place_outlined, value: '$_sitesCount', label: 'Locais visitados'),
                ],
              ),
              if (_avgDepth != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.swap_vert, color: DiverrTheme.primary),
                    title: const Text('Profundidade média', style: TextStyle(fontWeight: FontWeight.w700)),
                    trailing: Text(
                      formatMeters(_avgDepth),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                ),
              ],
              if (last != null) ...[
                const SectionTitle('Último mergulho'),
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x228ED8E5),
                      child: Icon(Icons.scuba_diving, color: DiverrTheme.primary),
                    ),
                    title: Text(last.diveSiteNome, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(formatDateTime(last.dataHora)),
                  ),
                ),
              ],
              const SectionTitle('Evolução'),
              _advanced(),
            ],
          ],
        ),
      ),
    );
  }
}
