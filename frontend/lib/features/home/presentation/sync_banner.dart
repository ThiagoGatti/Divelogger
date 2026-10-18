import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/sync_service.dart';
import '../../../core/session/session.dart';

/// Faixa discreta acima da barra de navegação: sincronizando, pendências, erros ou "sem conexão".
class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key});

  Widget _bar(
    BuildContext context, {
    required Widget leading,
    required String text,
    required Color color,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Material(
      color: color.withOpacity(.12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: color.withOpacity(.35))),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: DiverrTheme.dark.withOpacity(.85)),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncState>(
      valueListenable: SyncService.instance.state,
      builder: (context, s, _) {
        if (s.syncing) {
          return _bar(
            context,
            leading: const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            text: 'Sincronizando seus mergulhos…',
            color: DiverrTheme.primary,
          );
        }
        if (s.notice != null) {
          return _bar(
            context,
            leading: const Icon(Icons.info_outline, size: 18, color: DiverrTheme.warning),
            text: s.notice!,
            color: DiverrTheme.warning,
            onTap: SyncService.instance.dismissNotice,
            trailing: const Icon(Icons.close, size: 18),
          );
        }
        if (s.errors > 0) {
          return _bar(
            context,
            leading: const Icon(Icons.error_outline, size: 18, color: DiverrTheme.danger),
            text: '${s.errors} ${s.errors == 1 ? 'mergulho não sincronizou' : 'mergulhos não sincronizaram'}. Toque para resolver.',
            color: DiverrTheme.danger,
            onTap: () => showSyncIssuesSheet(context),
            trailing: const Icon(Icons.chevron_right, size: 18),
          );
        }
        if (s.pending > 0) {
          final label = '${s.pending} ${s.pending == 1 ? 'item aguardando' : 'itens aguardando'} envio';
          return _bar(
            context,
            leading: const Icon(Icons.cloud_upload_outlined, size: 18, color: DiverrTheme.warning),
            text: s.offline ? 'Sem conexão · $label' : label,
            color: DiverrTheme.warning,
            trailing: s.offline
                ? null
                : TextButton(
                    onPressed: SyncService.instance.syncNow,
                    style: TextButton.styleFrom(minimumSize: const Size(0, 30), padding: const EdgeInsets.symmetric(horizontal: 8)),
                    child: const Text('Enviar agora'),
                  ),
          );
        }
        if (s.offline) {
          return _bar(
            context,
            leading: const Icon(Icons.cloud_off_outlined, size: 18, color: DiverrTheme.muted),
            text: 'Sem conexão. Mostrando os dados salvos no aparelho.',
            color: DiverrTheme.muted,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// Lista o que o servidor recusou na sincronização, com "Tentar de novo" e "Descartar".
Future<void> showSyncIssuesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const _SyncIssuesSheet(),
  );
}

class _SyncIssuesSheet extends StatefulWidget {
  const _SyncIssuesSheet();

  @override
  State<_SyncIssuesSheet> createState() => _SyncIssuesSheetState();
}

class _SyncIssuesSheetState extends State<_SyncIssuesSheet> {
  List<PendingOp> _ops = [];

  @override
  void initState() {
    super.initState();
    _load();
    OfflineQueue.instance.revision.addListener(_load);
  }

  @override
  void dispose() {
    OfflineQueue.instance.revision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final user = AppSession.instance.currentUser;
    if (user == null) return;
    final ops = await OfflineQueue.instance.opsFor(user.id);
    if (!mounted) return;
    setState(() => _ops = ops.where((o) => o.error != null).toList());
  }

  String _title(PendingOp op) {
    final site = op.siteNome ?? 'Mergulho';
    final d = DateTime.tryParse(op.body['dataHora']?.toString() ?? '');
    final what = switch (op.type) {
      'create' => 'Novo mergulho',
      'update' => 'Edição',
      'photos' => 'Fotos',
      _ => 'Exclusão',
    };
    return d == null ? '$what · $site' : '$what · $site · ${formatDate(d)}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Problemas de sincronização', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                'O servidor recusou estes itens (por exemplo, o local foi desativado). '
                'Tente de novo ou descarte.',
                style: TextStyle(color: DiverrTheme.muted, height: 1.4),
              ),
            ),
            Flexible(
              child: _ops.isEmpty
                  ? const Padding(padding: EdgeInsets.all(24), child: Text('Nada pendente. Tudo certo!'))
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      children: [
                        for (final op in _ops)
                          Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_title(op), style: const TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 6),
                                  Text(op.error ?? '', style: const TextStyle(color: DiverrTheme.danger, height: 1.35)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => SyncService.instance.discard(op.opId),
                                        child: const Text('Descartar', style: TextStyle(color: DiverrTheme.danger)),
                                      ),
                                      TextButton(
                                        onPressed: () => SyncService.instance.retry(op.opId),
                                        child: const Text('Tentar de novo'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
}
