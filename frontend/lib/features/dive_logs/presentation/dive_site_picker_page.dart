import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ui/widgets.dart';
import '../../home/data/dive_site_model.dart';
import '../../home/data/dive_sites_api.dart';

/// Seleção de Dive Site para um mergulho. Devolve o [DiveSiteModel] escolhido.
class DiveSitePickerPage extends StatefulWidget {
  final String? selectedId;
  const DiveSitePickerPage({super.key, this.selectedId});

  @override
  State<DiveSitePickerPage> createState() => _DiveSitePickerPageState();
}

class _DiveSitePickerPageState extends State<DiveSitePickerPage> {
  final _api = DiveSitesApi();
  List<DiveSiteModel> _sites = [];
  String _query = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sites = await _api.findAll();
      if (!mounted) return;
      setState(() {
        _sites = sites;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  List<DiveSiteModel> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _sites;
    return _sites
        .where((s) =>
            s.nome.toLowerCase().contains(q) || s.localizacao.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Escolher Dive Site')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou cidade',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SkeletonList(count: 5, height: 76),
                  )
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: ErrorState(message: _error!, onRetry: _load),
                      )
                    : items.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: EmptyState(
                              icon: Icons.search_off,
                              title: 'Nenhum local encontrado',
                              message: 'Tente outro nome. Novos locais são cadastrados pela equipe Diverr.',
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final s = items[i];
                              final selected = s.id == widget.selectedId;
                              return Card(
                                child: ListTile(
                                  onTap: () => Navigator.pop(context, s),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: RemoteImage(
                                      url: s.coverUrl,
                                      cacheKey: s.images.isEmpty ? null : s.images.first.id,
                                      width: 52,
                                      height: 52,
                                      placeholderIcon: Icons.location_on,
                                    ),
                                  ),
                                  title: Text(s.nome, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  subtitle: Text(s.localizacao.isEmpty ? tipoLabel(s.tipo) : s.localizacao),
                                  trailing: selected
                                      ? const Icon(Icons.check_circle, color: DiverrTheme.primary)
                                      : const Icon(Icons.chevron_right),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
