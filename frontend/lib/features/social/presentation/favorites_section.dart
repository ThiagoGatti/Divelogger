import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/events.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ui/widgets.dart';
import '../../dive_logs/presentation/dive_site_picker_page.dart';
import '../../home/data/dive_site_model.dart';
import '../../home/data/dive_sites_api.dart';
import '../../home/presentation/dive_site_details_page.dart';
import '../../lists/data/list_models.dart';
import '../../lists/data/lists_api.dart';
import '../data/social_api.dart';

/// "Meus 4 favoritos": até 4 locais exibidos no perfil (como os 4 filmes favoritos do Letterboxd).
/// [editable] = perfil do próprio usuário. Em perfis de outras pessoas é só leitura.
class FavoritesSection extends StatefulWidget {
  final int userId;
  final bool editable;
  const FavoritesSection({super.key, required this.userId, required this.editable});

  @override
  State<FavoritesSection> createState() => _FavoritesSectionState();
}

class _FavoritesSectionState extends State<FavoritesSection> {
  final _lists = ListsApi();
  List<ListItem> _items = [];
  bool _loading = true;
  bool _saving = false;

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
      final detail = widget.editable
          ? await _lists.favorites()
          : await SocialApi().userFavorites(widget.userId);
      if (!mounted) return;
      setState(() {
        _items = detail.items;
        _loading = false;
      });
    } on ApiException {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(List<String> ids) async {
    setState(() => _saving = true);
    try {
      final detail = await _lists.setFavorites(ids);
      if (!mounted) return;
      setState(() {
        _items = detail.items;
        _saving = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSnack(context, e.message, error: true);
    }
  }

  Future<void> _pickFor(int slot) async {
    final site = await Navigator.of(context).push<DiveSiteModel>(
      MaterialPageRoute(builder: (_) => const DiveSitePickerPage()),
    );
    if (site == null) return;

    final ids = _items.map((i) => i.siteId).toList();
    final existingIndex = ids.indexOf(site.id);
    if (existingIndex != -1 && existingIndex != slot) {
      if (mounted) showSnack(context, 'Este local já está nos seus favoritos.', error: true);
      return;
    }
    if (slot < ids.length) {
      ids[slot] = site.id;
    } else {
      ids.add(site.id);
    }
    await _save(ids);
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

  Future<void> _slotTap(int slot) async {
    final filled = slot < _items.length;

    if (!widget.editable) {
      if (filled) _openSite(_items[slot]);
      return;
    }
    if (!filled) {
      await _pickFor(_items.length); // adiciona no primeiro espaço livre
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Ver local'),
              onTap: () => Navigator.pop(ctx, 'open'),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Trocar por outro local'),
              onTap: () => Navigator.pop(ctx, 'swap'),
            ),
            ListTile(
              leading: const Icon(Icons.close, color: DiverrTheme.danger),
              title: const Text('Remover dos favoritos', style: TextStyle(color: DiverrTheme.danger)),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == 'open') {
      await _openSite(_items[slot]);
    } else if (action == 'swap') {
      await _pickFor(slot);
    } else if (action == 'remove') {
      final ids = _items.map((i) => i.siteId).toList()..removeAt(slot);
      await _save(ids);
    }
  }

  Widget _slot(int slot) {
    final filled = slot < _items.length;
    final item = filled ? _items[slot] : null;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: slot < 3 ? 8 : 0),
        child: AspectRatio(
          aspectRatio: .75,
          child: InkWell(
            onTap: _saving ? null : () => _slotTap(slot),
            borderRadius: BorderRadius.circular(14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: filled
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        RemoteImage(
                          url: item!.coverUrl,
                          cacheKey: item.coverImageId,
                          placeholderIcon: Icons.location_on,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: Text(
                            item.siteNome,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5, height: 1.15),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: widget.editable ? context.softFill : context.surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: DiverrTheme.primary.withOpacity(widget.editable ? .35 : .12),
                        ),
                      ),
                      child: widget.editable
                          ? const Icon(Icons.add, color: DiverrTheme.primary)
                          : const SizedBox.shrink(),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.editable && !_loading && _items.isEmpty) {
      return const SizedBox.shrink(); // perfil de outra pessoa sem favoritos: não mostra a seção
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.editable ? 'MEUS 4 FAVORITOS' : 'FAVORITOS',
                style: const TextStyle(fontSize: 11.5, letterSpacing: .8, fontWeight: FontWeight.w900, color: DiverrTheme.muted),
              ),
            ),
            if (_saving) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        const SizedBox(height: 10),
        if (_loading)
          const SkeletonList(count: 1, height: 110)
        else
          Row(children: [for (var i = 0; i < 4; i++) _slot(i)]),
      ],
    );
  }
}
