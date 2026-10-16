import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/events.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ui/widgets.dart';
import '../data/list_models.dart';
import '../data/lists_api.dart';

/// Linha de um local dentro de uma lista (com posição quando a lista é ranqueada).
class ListItemTile extends StatelessWidget {
  final ListItem item;
  final bool showPosition;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final Widget? leadingHandle;

  const ListItemTile({
    super.key,
    required this.item,
    required this.showPosition,
    required this.onTap,
    this.onRemove,
    this.leadingHandle,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: item.ativo ? 1 : .55,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                if (showPosition)
                  SizedBox(
                    width: 38,
                    child: Text(
                      '${item.position}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: DiverrTheme.primary),
                    ),
                  ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RemoteImage(
                    url: item.coverUrl,
                    cacheKey: item.coverImageId,
                    width: 60,
                    height: 60,
                    placeholderIcon: Icons.location_on,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.siteNome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                      const SizedBox(height: 2),
                      Text(
                        item.localizacao.isEmpty ? '—' : item.localizacao,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: DiverrTheme.muted, fontSize: 12.5),
                      ),
                      if (!item.ativo)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: InfoChip(icon: Icons.block, text: 'Local desativado', color: DiverrTheme.danger),
                        ),
                    ],
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Remover',
                  ),
                if (leadingHandle != null) leadingHandle!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cria ou edita uma lista. Devolve a lista salva (ou null se cancelado).
Future<ListDetail?> showListFormSheet(BuildContext context, {ListDetail? existing}) {
  return showModalBottomSheet<ListDetail>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _ListFormSheet(existing: existing),
    ),
  );
}

class _ListFormSheet extends StatefulWidget {
  final ListDetail? existing;
  const _ListFormSheet({this.existing});

  @override
  State<_ListFormSheet> createState() => _ListFormSheetState();
}

class _ListFormSheetState extends State<_ListFormSheet> {
  final _api = ListsApi();
  late final TextEditingController _nome = TextEditingController(text: widget.existing?.nome ?? '');
  late final TextEditingController _desc = TextEditingController(text: widget.existing?.descricao ?? '');
  late bool _ranked = widget.existing?.ranked ?? false;
  bool _saving = false;

  @override
  void dispose() {
    _nome.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nome = _nome.text.trim();
    if (nome.isEmpty) {
      showSnack(context, 'Dê um nome para a lista.', error: true);
      return;
    }
    final desc = _desc.text.trim().isEmpty ? null : _desc.text.trim();

    setState(() => _saving = true);
    try {
      final saved = widget.existing == null
          ? await _api.create(nome, desc, _ranked)
          : await _api.update(widget.existing!.id, nome, desc, _ranked);
      AppEvents.notifyListsChanged();
      if (!mounted) return;
      Navigator.pop(context, saved);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? 'Nova lista' : 'Editar lista',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nome,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Nome da lista', hintText: 'Ex.: Top 10 naufrágios'),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _desc,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descrição (opcional)', alignLabelWithHint: true),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lista ranqueada', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Mostra a posição (#1, #2...) e permite reordenar'),
              value: _ranked,
              onChanged: (v) => setState(() => _ranked = v),
            ),
            const SizedBox(height: 8),
            LoadingButton(
              loading: _saving,
              onPressed: _save,
              label: widget.existing == null ? 'Criar lista' : 'Salvar',
            ),
          ],
        ),
      ),
    );
  }
}

/// "Adicionar a uma lista" a partir de um Dive Site.
Future<void> showAddToListSheet(BuildContext context, String siteId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _AddToListSheet(siteId: siteId),
  );
}

class _AddToListSheet extends StatefulWidget {
  final String siteId;
  const _AddToListSheet({required this.siteId});

  @override
  State<_AddToListSheet> createState() => _AddToListSheetState();
}

class _AddToListSheetState extends State<_AddToListSheet> {
  final _api = ListsApi();
  List<ListSummary> _lists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final lists = await _api.mine();
      if (!mounted) return;
      setState(() {
        _lists = lists;
        _loading = false;
      });
    } on ApiException {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add(ListSummary list) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await _api.addItem(list.id, widget.siteId);
      AppEvents.notifyListsChanged();
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Adicionado a "${list.nome}".')));
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _createAndAdd() async {
    final created = await showListFormSheet(context);
    if (created == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await _api.addItem(created.id, widget.siteId);
      AppEvents.notifyListsChanged();
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Lista "${created.nome}" criada e local adicionado.')));
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Adicionar a uma lista', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x228ED8E5),
                child: Icon(Icons.add, color: DiverrTheme.primary),
              ),
              title: const Text('Nova lista', style: TextStyle(fontWeight: FontWeight.w800)),
              onTap: _createAndAdd,
            ),
            Flexible(
              child: _loading
                  ? const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final l in _lists)
                          ListTile(
                            leading: const Icon(Icons.format_list_numbered_rtl, color: DiverrTheme.primary),
                            title: Text(l.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('${l.itemsCount} ${l.itemsCount == 1 ? 'local' : 'locais'}'),
                            onTap: () => _add(l),
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
