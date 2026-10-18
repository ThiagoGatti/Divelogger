import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ui/widgets.dart';
import '../../home/data/dive_sites_api.dart';
import '../../home/presentation/dive_site_details_page.dart';
import '../data/operator_models.dart';
import '../data/operators_api.dart';

/// Operadora vista por qualquer usuário: foto, endereço e os locais onde atua.
class OperatorDetailsPage extends StatefulWidget {
  final String operatorId;
  final String initialName;
  const OperatorDetailsPage({super.key, required this.operatorId, required this.initialName});

  @override
  State<OperatorDetailsPage> createState() => _OperatorDetailsPageState();
}

class _OperatorDetailsPageState extends State<OperatorDetailsPage> {
  OperatorDetail? _op;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await OperatorsApi().get(widget.operatorId);
      if (!mounted) return;
      setState(() {
        _op = d;
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

  Future<void> _openSite(SiteRef ref) async {
    try {
      final site = await DiveSitesApi().findById(ref.id);
      if (!mounted) return;
      await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => DiveSiteDetailsPage(site: site)));
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final op = _op;
    return Scaffold(
      appBar: AppBar(title: Text(op?.nome ?? widget.initialName)),
      body: _loading
          ? const Padding(padding: EdgeInsets.all(20), child: SkeletonList(count: 3, height: 100))
          : _error != null
              ? Padding(padding: const EdgeInsets.all(20), child: ErrorState(message: _error!, onRetry: _load))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(DiverrTheme.radius),
                      child: SizedBox(
                        height: 200,
                        child: RemoteImage(
                          url: op!.photoUrl,
                          cacheKey: op.photoId,
                          width: double.infinity,
                          height: 200,
                          placeholderIcon: Icons.storefront_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(op.nome, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    if (op.endereco != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.place_outlined, size: 20, color: DiverrTheme.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(op.endereco!, style: const TextStyle(height: 1.4))),
                        ],
                      ),
                    ],
                    const SectionTitle('Atua em'),
                    if (op.sites.isEmpty)
                      const Text('Ainda não vinculada a nenhum local.', style: TextStyle(color: DiverrTheme.muted))
                    else
                      for (final s in op.sites)
                        Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            onTap: () => _openSite(s),
                            leading: const Icon(Icons.location_on_outlined, color: DiverrTheme.primary),
                            title: Text(s.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: s.localizacao.isEmpty ? null : Text(s.localizacao),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        ),
                  ],
                ),
    );
  }
}
