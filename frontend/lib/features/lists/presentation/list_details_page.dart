import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/events.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ui/widgets.dart';
import '../../dive_logs/presentation/dive_site_picker_page.dart';
import '../../home/data/dive_site_model.dart';
import '../../home/data/dive_sites_api.dart';
import '../../home/presentation/dive_site_details_page.dart';
import '../data/list_models.dart';
import '../data/lists_api.dart';
import 'list_widgets.dart';

/// Detalhes de uma lista: adicionar/remover locais, reordenar (se ranqueada), editar e excluir.
class ListDetailsPage extends StatefulWidget {
  final String listId;
  final String initialTitle;
  const ListDetailsPage({super.key, required this.listId, required this.initialTitle});

  @override
  State<ListDetailsPage> createState() => _ListDetailsPageState();
}

class _ListDetailsPageState extends State<ListDetailsPage> {
  final _api = ListsApi();
  ListDetail? _list;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final l = await _api.get(widget.listId);
      if (!mounted) return;
      setState(() {
        _list = l;
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

  Future<void> _addSite() async {
    final site = await Navigator.of(context).push<DiveSiteModel>(
      MaterialPageRoute(builder: (_) => const DiveSitePickerPage()),
    );
    if (site == null) return;
    try {
      final updated = await _api.addItem(widget.listId, site.id);
      AppEvents.notifyListsChanged();
      if (mounted) setState(() => _list = updated);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _remove(ListItem item) async {
    try {
      final updated = await _api.removeItem(widget.listId, item.id);
      AppEvents.notifyListsChanged();
      if (mounted) setState(() => _list = updated);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _openSite(ListItem item) async {
    try {
      final site = await DiveSitesApi().findById(item.siteId);
      if (!mounted) return;
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => DiveSiteDetailsPage(site: site)),
      );
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    final list = _list;
    if (list == null) return;
    if (newIndex > oldIndex) newIndex -= 1;

    final items = List<ListItem>.of(list.items);
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);

    // otimista: mostra a nova ordem e confirma no servidor
    setState(() {
      _list = ListDetail(
        id: list.id,
        nome: list.nome,
        descricao: list.descricao,
        ranked: list.ranked,
        tipo: list.tipo,
        items: [
          for (var i = 0; i < items.length; i++)
            ListItem(
              id: items[i].id,
              position: i + 1,
              nota: items[i].nota,
              siteId: items[i].siteId,
              siteNome: items[i].siteNome,
              localizacao: items[i].localizacao,
              tipo: items[i].tipo,
              ativo: items[i].ativo,
              coverUrl: items[i].coverUrl,
              coverImageId: items[i].coverImageId,
            ),
        ],
      );
    });

    try {
      final updated = await _api.reorder(widget.listId, items.map((i) => i.id).toList());
      if (mounted) setState(() => _list = updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      showSnack(context, e.message, error: true);
      _load();
    }
  }

  Future<void> _edit() async {
    final saved = await showListFormSheet(context, existing: _list);
    if (saved != null && mounted) setState(() => _list = saved);
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'Excluir lista?',
      message: 'A lista "${_list?.nome}" será apagada. Os locais continuam existindo.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok) return;
    try {
      await _api.delete(widget.listId);
      AppEvents.notifyListsChanged();
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;

    return Scaffold(
      appBar: AppBar(
        title: Text(list?.nome ?? widget.initialTitle),
        actions: [
          if (list != null)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _edit();
                if (v == 'delete') _delete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar'), contentPadding: EdgeInsets.zero)),
                PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: DiverrTheme.danger), title: Text('Excluir', style: TextStyle(color: DiverrTheme.danger)), contentPadding: EdgeInsets.zero)),
              ],
            ),
        ],
      ),
      floatingActionButton: list == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _addSite,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Adicionar local', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
      body: _loading
          ? const Padding(padding: EdgeInsets.all(20), child: SkeletonList(count: 4, height: 80))
          : _error != null
              ? Padding(padding: const EdgeInsets.all(20), child: ErrorState(message: _error!, onRetry: _load))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                  children: [
                    if (list!.descricao != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(list.descricao!, style: const TextStyle(color: DiverrTheme.muted, height: 1.4)),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          InfoChip(icon: Icons.place_outlined, text: '${list.items.length} ${list.items.length == 1 ? 'local' : 'locais'}'),
                          if (list.ranked) const InfoChip(icon: Icons.format_list_numbered, text: 'Ranqueada', color: DiverrTheme.gold),
                        ],
                      ),
                    ),
                    if (list.items.isEmpty)
                      EmptyState(
                        icon: Icons.format_list_bulleted,
                        title: 'Lista vazia',
                        message: 'Adicione os locais que fazem parte desta lista.',
                        actionLabel: 'Adicionar local',
                        onAction: _addSite,
                      )
                    else if (list.ranked)
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        onReorder: _onReorder,
                        children: [
                          for (var i = 0; i < list.items.length; i++)
                            Padding(
                              key: ValueKey(list.items[i].id),
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ListItemTile(
                                item: list.items[i],
                                showPosition: true,
                                onTap: () => _openSite(list.items[i]),
                                onRemove: () => _remove(list.items[i]),
                                leadingHandle: ReorderableDragStartListener(
                                  index: i,
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(Icons.drag_handle, color: DiverrTheme.muted),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    else
                      for (final item in list.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ListItemTile(
                            item: item,
                            showPosition: false,
                            onTap: () => _openSite(item),
                            onRemove: () => _remove(item),
                          ),
                        ),
                  ],
                ),
    );
  }
}
