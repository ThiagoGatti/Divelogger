import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/events.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ui/widgets.dart';
import '../../home/data/dive_sites_api.dart';
import '../../home/presentation/dive_site_details_page.dart';
import '../data/list_models.dart';
import '../data/lists_api.dart';
import 'list_details_page.dart';
import 'list_widgets.dart';

/// Aba "Quero mergulhar": a lista pro futuro (locais que o usuário quer visitar).
class WishlistTab extends StatefulWidget {
  const WishlistTab({super.key});

  @override
  State<WishlistTab> createState() => _WishlistTabState();
}

class _WishlistTabState extends State<WishlistTab> {
  final _api = ListsApi();
  ListDetail? _list;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    AppEvents.listsChanged.addListener(_load);
  }

  @override
  void dispose() {
    AppEvents.listsChanged.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final l = await _api.wishlist();
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

  Future<void> _remove(ListItem item) async {
    try {
      final updated = await _api.removeFromWishlist(item.siteId);
      if (mounted) setState(() => _list = updated);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _open(ListItem item) async {
    try {
      final site = await DiveSitesApi().findById(item.siteId);
      if (!mounted) return;
      await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => DiveSiteDetailsPage(site: site)));
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          if (_loading)
            const SkeletonList(count: 3, height: 80)
          else if (_error != null)
            ErrorState(message: _error!, onRetry: _load)
          else if (list == null || list.items.isEmpty)
            const EmptyState(
              icon: Icons.bookmark_border,
              title: 'Sua lista pro futuro está vazia',
              message: 'Toque no marcador em qualquer Dive Site para guardar os mergulhos que você quer fazer.',
            )
          else
            for (final item in list.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ListItemTile(
                  item: item,
                  showPosition: false,
                  onTap: () => _open(item),
                  onRemove: () => _remove(item),
                ),
              ),
        ],
      ),
    );
  }
}

/// Aba "Listas": listas criadas pelo usuário, ranqueadas ou não.
class ListsTab extends StatefulWidget {
  const ListsTab({super.key});

  @override
  State<ListsTab> createState() => _ListsTabState();
}

class _ListsTabState extends State<ListsTab> {
  final _api = ListsApi();
  List<ListSummary> _lists = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    AppEvents.listsChanged.addListener(_load);
  }

  @override
  void dispose() {
    AppEvents.listsChanged.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final lists = await _api.mine();
      if (!mounted) return;
      setState(() {
        _lists = lists;
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
    final created = await showListFormSheet(context);
    if (created == null || !mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ListDetailsPage(listId: created.id, initialTitle: created.nome)),
    );
    _load();
  }

  Future<void> _open(ListSummary l) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ListDetailsPage(listId: l.id, initialTitle: l.nome)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          if (_loading)
            const SkeletonList(count: 3, height: 84)
          else if (_error != null)
            ErrorState(message: _error!, onRetry: _load)
          else ...[
            OutlinedButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Nova lista'),
            ),
            const SizedBox(height: 14),
            if (_lists.isEmpty)
              const EmptyState(
                icon: Icons.format_list_numbered,
                title: 'Nenhuma lista ainda',
                message: 'Crie listas como "Top 10 naufrágios" ou "Meus favoritos do Brasil", ranqueadas ou não.',
              )
            else
              for (final l in _lists)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ImageSideCard(
                    imageUrl: l.coverUrl,
                    cacheKey: l.coverImageId,
                    placeholderIcon: Icons.format_list_numbered,
                    imageWidth: 86,
                    minHeight: 86,
                    onTap: () => _open(l),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            InfoChip(text: '${l.itemsCount} ${l.itemsCount == 1 ? 'local' : 'locais'}'),
                            if (l.ranked) const InfoChip(icon: Icons.format_list_numbered, text: 'Ranqueada', color: DiverrTheme.gold),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
