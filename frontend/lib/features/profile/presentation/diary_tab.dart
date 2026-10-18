import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/ui/widgets.dart';
import '../../dive_logs/data/dive_log_model.dart';
import '../../dive_logs/presentation/dive_log_details_page.dart';
import '../../dive_logs/presentation/dive_log_form_page.dart';

/// Diário: seus mergulhos em ordem cronológica, agrupados por mês (como o journal do Letterboxd).
class DiaryTab extends StatelessWidget {
  final List<DiveLogModel> logs;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;

  const DiaryTab({
    super.key,
    required this.logs,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  Future<void> _open(BuildContext context, DiveLogModel log) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DiveLogDetailsPage(log: log)),
    );
    if (changed == true) onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (loading) {
      children.add(const SkeletonList(count: 5, height: 76));
    } else if (error != null && logs.isEmpty) {
      children.add(ErrorState(message: error!, onRetry: onRefresh));
    } else if (logs.isEmpty) {
      children.add(EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'Nenhum mergulho no diário',
        message: 'Cada mergulho que você registrar aparece aqui, em ordem cronológica.',
        actionLabel: 'Registrar mergulho',
        onAction: () => openDiveLogForm(context),
      ));
    } else {
      String? currentMonth;
      var monthCount = 0;
      // contagem por mês para o cabeçalho
      final counts = <String, int>{};
      for (final l in logs) {
        final k = formatMonthYear(l.dataHora);
        counts[k] = (counts[k] ?? 0) + 1;
      }

      for (final l in logs) {
        final month = formatMonthYear(l.dataHora);
        if (month != currentMonth) {
          currentMonth = month;
          monthCount = counts[month] ?? 0;
          children.add(Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    month.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w900,
                      color: DiverrTheme.muted,
                    ),
                  ),
                ),
                Text(
                  '$monthCount ${monthCount == 1 ? 'mergulho' : 'mergulhos'}',
                  style: const TextStyle(fontSize: 12, color: DiverrTheme.muted),
                ),
              ],
            ),
          ));
        }
        children.add(_DiaryRow(log: l, onTap: () => _open(context, l)));
      }
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: children,
      ),
    );
  }
}

class _DiaryRow extends StatelessWidget {
  final DiveLogModel log;
  final VoidCallback onTap;
  const _DiaryRow({required this.log, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = log.dataHora;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DiverrTheme.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  Text(
                    two(d.day),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: DiverrTheme.primary, height: 1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    weekdayShort(d),
                    style: const TextStyle(fontSize: 11.5, color: DiverrTheme.muted, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: RemoteImage(
                url: log.coverUrl,
                cacheKey: log.imagens.isEmpty ? null : log.imagens.first.id,
                localPath: log.imagens.isEmpty && log.localPhotos.isNotEmpty ? log.localPhotos.first : null,
                width: 54,
                height: 54,
                placeholderIcon: Icons.scuba_diving,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.diveSiteNome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if ((log.notaExperiencia ?? 0) > 0) ...[
                        RatingStars(value: log.notaExperiencia!, size: 14),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          [
                            if (log.profundidadeMaxima != null) formatMeters(log.profundidadeMaxima),
                            if (log.duracaoMinutos != null) formatDuration(log.duracaoMinutos),
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: DiverrTheme.muted, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (log.pending)
              Icon(
                log.syncError != null ? Icons.error_outline : Icons.cloud_upload_outlined,
                size: 18,
                color: log.syncError != null ? DiverrTheme.danger : DiverrTheme.warning,
              )
            else if (log.observacoes != null && log.observacoes!.isNotEmpty)
              const Icon(Icons.notes, size: 18, color: DiverrTheme.muted),
            const Icon(Icons.chevron_right, color: DiverrTheme.muted),
          ],
        ),
      ),
    );
  }
}
