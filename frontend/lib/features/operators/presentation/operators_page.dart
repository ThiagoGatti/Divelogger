import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ui/widgets.dart';
import '../data/operator_models.dart';
import '../data/operators_api.dart';
import 'operator_details_page.dart';
import 'operator_form_page.dart';

/// Gestão de operadoras (ADMIN): lista, cadastro e edição.
class OperatorsPage extends StatefulWidget {
  const OperatorsPage({super.key});

  @override
  State<OperatorsPage> createState() => _OperatorsPageState();
}

class _OperatorsPageState extends State<OperatorsPage> {
  final _api = OperatorsApi();
  List<OperatorSummary> _items = [];
  String _query = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _api.list(includeInactive: true);
      if (!mounted) return;
      setState(() {
        _items = list;
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
    final created = await Navigator.of(context).push<OperatorDetail>(
      MaterialPageRoute(builder: (_) => const OperatorFormPage()),
    );
    if (created != null) _load();
  }

  Future<void> _open(OperatorSummary o) async {
    try {
      final detail = await _api.get(o.id);
      if (!mounted) return;
      final saved = await Navigator.of(context).push<OperatorDetail>(
        MaterialPageRoute(builder: (_) => OperatorFormPage(existing: detail)),
      );
      if (saved != null) _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final items = _items
        .where((o) => q.isEmpty || o.nome.toLowerCase().contains(q) || (o.endereco ?? '').toLowerCase().contains(q))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Operadoras')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Nova operadora', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
          children: [
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(hintText: 'Buscar operadora', prefixIcon: Icon(Icons.search)),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const SkeletonList(count: 4, height: 90)
            else if (_error != null)
              ErrorState(message: _error!, onRetry: _load)
            else if (items.isEmpty)
              EmptyState(
                icon: Icons.storefront_outlined,
                title: _items.isEmpty ? 'Nenhuma operadora ainda' : 'Nada encontrado',
                message: _items.isEmpty
                    ? 'Cadastre as operadoras de mergulho e vincule-as aos locais onde atuam.'
                    : 'Tente outro termo de busca.',
                actionLabel: _items.isEmpty ? 'Cadastrar operadora' : null,
                onAction: _items.isEmpty ? _create : null,
              )
            else
              for (final o in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Opacity(
                    opacity: o.ativo ? 1 : .55,
                    child: ImageSideCard(
                      imageUrl: o.photoUrl,
                      cacheKey: o.photoId,
                      placeholderIcon: Icons.storefront_outlined,
                      imageWidth: 90,
                      minHeight: 90,
                      onTap: () => _open(o),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(o.nome, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          if (o.endereco != null) ...[
                            const SizedBox(height: 4),
                            Text(o.endereco!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: DiverrTheme.muted, fontSize: 12.5)),
                          ],
                          if (!o.ativo) ...[
                            const SizedBox(height: 6),
                            const InfoChip(icon: Icons.block, text: 'Desativada', color: DiverrTheme.danger),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
