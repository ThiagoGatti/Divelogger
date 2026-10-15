import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/events.dart';
import '../../../core/format.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/ui/widgets.dart';
import '../../dive_logs/data/dive_log_model.dart';
import '../../dive_logs/data/dive_logs_api.dart';
import '../../dive_logs/presentation/dive_log_details_page.dart';
import '../../dive_logs/presentation/dive_log_form_page.dart';

class DiveLogsPage extends StatefulWidget {
  const DiveLogsPage({super.key});

  @override
  State<DiveLogsPage> createState() => _DiveLogsPageState();
}

class _DiveLogsPageState extends State<DiveLogsPage> {
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

  Future<void> _create() async {
    await openDiveLogForm(context);
  }

  Future<void> _open(DiveLogModel log) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DiveLogDetailsPage(log: log)),
    );
    if (changed == true) _load();
  }

  Widget _usageBanner() {
    return ValueListenableBuilder<int>(
      valueListenable: AppSession.instance.changed,
      builder: (_, __, ___) {
        final ent = AppSession.instance.entitlements;
        final max = ent.maxDiveLogs;
        if (max == null) return const SizedBox.shrink();

        final used = _logs.length > ent.diveLogsUsed ? _logs.length : ent.diveLogsUsed;
        final progress = (used / max).clamp(0.0, 1.0);
        final nearLimit = progress >= .8;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const PlanBadge(premium: false),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$used de $max mergulhos',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      TextButton(
                        onPressed: () => showUpgradeSheet(context),
                        child: const Text('Upgrade'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: DiverrTheme.ocean.withOpacity(.3),
                      color: nearLimit ? DiverrTheme.warning : DiverrTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _items() {
    final widgets = <Widget>[];
    String? currentMonth;
    for (final log in _logs) {
      final month = formatMonthYear(log.dataHora);
      if (month != currentMonth) {
        currentMonth = month;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Text(
            month.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
              color: DiverrTheme.muted,
            ),
          ),
        ));
      }
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _DiveLogCard(log: log, onTap: () => _open(log)),
      ));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
              children: [
                const PageHeader(
                  title: 'Meus mergulhos',
                  subtitle: 'Seu diário pessoal de experiências subaquáticas.',
                ),
                _usageBanner(),
                if (_loading)
                  const SkeletonList(count: 4, height: 104)
                else if (_error != null && _logs.isEmpty)
                  ErrorState(message: _error!, onRetry: _load)
                else if (_logs.isEmpty)
                  EmptyState(
                    icon: Icons.scuba_diving,
                    title: 'Seu diário está vazio',
                    message: 'Registre seu primeiro mergulho com local, profundidade, condições e fotos.',
                    actionLabel: 'Registrar mergulho',
                    onAction: _create,
                  )
                else
                  ..._items(),
              ],
            ),
          ),
          if (!_loading && _logs.isNotEmpty)
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                onPressed: _create,
                icon: const Icon(Icons.add),
                label: const Text('Novo mergulho', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiveLogCard extends StatelessWidget {
  final DiveLogModel log;
  final VoidCallback onTap;
  const _DiveLogCard({required this.log, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DiverrTheme.radius),
        boxShadow: DiverrTheme.softShadow,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 108,
            child: Row(
              children: [
                SizedBox(
                  width: 108,
                  height: 108,
                  child: RemoteImage(
                    url: log.coverUrl,
                    cacheKey: log.imagens.isEmpty ? null : log.imagens.first.id,
                    placeholderIcon: Icons.scuba_diving,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          log.diveSiteNome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          formatDateTime(log.dataHora),
                          style: const TextStyle(color: DiverrTheme.muted, fontSize: 12.5),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (log.profundidadeMaxima != null)
                              InfoChip(icon: Icons.arrow_downward, text: formatMeters(log.profundidadeMaxima)),
                            if (log.duracaoMinutos != null)
                              InfoChip(icon: Icons.timer_outlined, text: formatDuration(log.duracaoMinutos), color: DiverrTheme.secondary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.chevron_right, color: DiverrTheme.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
