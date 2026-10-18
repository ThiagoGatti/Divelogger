import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ui/widgets.dart';
import '../../home/data/dive_site_model.dart';
import '../../home/data/dive_sites_api.dart';

/// Escolha de VÁRIOS Dive Sites (ex.: onde uma operadora atua). Devolve um mapa id -> nome dos escolhidos.
class SitesMultiPickerPage extends StatefulWidget {
  final Set<String> selectedIds;
  final Map<String, String> initialNames;
  final String title;
  const SitesMultiPickerPage({
    super.key,
    required this.selectedIds,
    this.initialNames = const {},
    this.title = 'Escolher locais',
  });

  @override
  State<SitesMultiPickerPage> createState() => _SitesMultiPickerPageState();
}

class _SitesMultiPickerPageState extends State<SitesMultiPickerPage> {
  final _api = DiveSitesApi();
  late final Set<String> _selected = {...widget.selectedIds};
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

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final items = _sites
        .where((s) => q.isEmpty || s.nome.toLowerCase().contains(q) || s.localizacao.toLowerCase().contains(q))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(hintText: 'Buscar local', prefixIcon: Icon(Icons.search)),
            ),
          ),
          Expanded(
            child: _loading
                ? const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: SkeletonList(count: 5, height: 64))
                : _error != null
                    ? Padding(padding: const EdgeInsets.all(20), child: ErrorState(message: _error!, onRetry: _load))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final s = items[i];
                          return CheckboxListTile(
                            value: _selected.contains(s.id),
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _selected.add(s.id);
                              } else {
                                _selected.remove(s.id);
                              }
                            }),
                            title: Text(s.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(s.localizacao.isEmpty ? tipoLabel(s.tipo) : s.localizacao),
                            activeColor: DiverrTheme.primary,
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: () {
              final names = <String, String>{};
              for (final id in _selected) {
                DiveSiteModel? site;
                for (final s in _sites) {
                  if (s.id == id) site = s;
                }
                names[id] = site?.nome ?? widget.initialNames[id] ?? 'Local';
              }
              Navigator.pop(context, names);
            },
            child: Text('Confirmar (${_selected.length})'),
          ),
        ),
      ),
    );
  }
}
