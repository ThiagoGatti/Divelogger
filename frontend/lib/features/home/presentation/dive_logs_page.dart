import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/ui/widgets.dart';
import '../../dive_logs/data/dive_log_model.dart';
import '../../dive_logs/presentation/dive_log_card.dart';
import '../../dive_logs/presentation/dive_log_details_page.dart';
import '../../dive_logs/presentation/dive_log_form_page.dart';

/// Aba "Mergulhos" do perfil: todos os mergulhos, do mais recente ao mais antigo.
class DiveLogsTab extends StatelessWidget {
  final List<DiveLogModel> logs;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;

  /// Perfil de outra pessoa: sem botão de registrar mergulho.
  final bool readOnly;

  const DiveLogsTab({
    super.key,
    required this.logs,
    required this.loading,
    required this.error,
    required this.onRefresh,
    this.readOnly = false,
  });

  Future<void> _open(BuildContext context, DiveLogModel log) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DiveLogDetailsPage(log: log)),
    );
    if (changed == true) onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          if (loading)
            const SkeletonList(count: 4, height: 104)
          else if (error != null && logs.isEmpty)
            ErrorState(message: error!, onRetry: onRefresh)
          else if (logs.isEmpty)
            EmptyState(
              icon: Icons.scuba_diving,
              title: readOnly ? 'Nenhum mergulho ainda' : 'Seu diário está vazio',
              message: readOnly
                  ? 'Esta pessoa ainda não registrou mergulhos.'
                  : 'Registre seu primeiro mergulho com local, profundidade, condições e fotos.',
              actionLabel: readOnly ? null : 'Registrar mergulho',
              onAction: readOnly ? null : () => openDiveLogForm(context),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${logs.length} ${logs.length == 1 ? 'mergulho' : 'mergulhos'}',
                style: const TextStyle(color: DiverrTheme.muted, fontWeight: FontWeight.w700),
              ),
            ),
            for (final l in logs)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DiveLogCard(log: l, onTap: () => _open(context, l)),
              ),
          ],
        ],
      ),
    );
  }
}
