import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/events.dart';
import '../../../core/format.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/ui/widgets.dart';
import '../../dive_logs/presentation/dive_log_details_page.dart';
import '../data/social_api.dart';
import '../data/social_models.dart';
import 'public_profile_page.dart';
import 'social_widgets.dart';
import 'user_search_page.dart';

/// Atividade dos amigos: mergulhos de quem você segue (respeitando a privacidade de cada um),
/// com reações em emoji e comentários.
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final _api = SocialApi();
  List<FeedItem> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    AppEvents.followsChanged.addListener(_load);
  }

  @override
  void dispose() {
    AppEvents.followsChanged.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!AppSession.instance.isLoggedIn) return;
    try {
      final p = await _api.feed(page: 0);
      if (!mounted) return;
      setState(() {
        _items = p.items;
        _hasMore = p.hasMore;
        _page = 0;
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

  Future<void> _more() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final p = await _api.feed(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...p.items];
        _hasMore = p.hasMore;
        _page = p.page;
        _loadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      showSnack(context, e.message, error: true);
    }
  }

  Future<void> _openSearch() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserSearchPage()));
    _load(); // pode ter seguido alguém
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          children: [
            PageHeader(
              title: 'Amigos',
              subtitle: 'Os mergulhos de quem você segue.',
              trailing: IconButton.filledTonal(
                onPressed: _openSearch,
                icon: const Icon(Icons.person_search_outlined),
                tooltip: 'Encontrar mergulhadores',
              ),
            ),
            if (_loading)
              const SkeletonList(count: 3, height: 220)
            else if (_error != null && _items.isEmpty)
              ErrorState(message: _error!, onRetry: _load)
            else if (_items.isEmpty)
              EmptyState(
                icon: Icons.group_outlined,
                title: 'Seu feed está vazio',
                message:
                    'Siga outros mergulhadores para ver os mergulhos deles aqui. '
                    'Quem você segue e que também te segue vira amigo.',
                actionLabel: 'Encontrar mergulhadores',
                onAction: _openSearch,
              )
            else ...[
              for (final item in _items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _FeedCard(key: ValueKey(item.dive.id), item: item),
                ),
              if (_hasMore)
                Center(
                  child: _loadingMore
                      ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())
                      : TextButton(onPressed: _more, child: const Text('Carregar mais')),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedCard extends StatefulWidget {
  final FeedItem item;
  const _FeedCard({super.key, required this.item});

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  late SocialSummary _social = widget.item.social;

  Future<void> _openDetails() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DiveLogDetailsPage(log: widget.item.dive)),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublicProfilePage(userId: widget.item.dive.ownerId)),
    );
  }

  Widget _ratingChip(String label, double? v) {
    if (v == null || v <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: const TextStyle(fontSize: 12, color: DiverrTheme.muted)),
        RatingStars(value: v, size: 14),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.item.dive;
    final hasPhoto = d.imagens.isNotEmpty && d.coverUrl != null;
    final hasRatings = (d.notaLocal ?? 0) > 0 || (d.notaExperiencia ?? 0) > 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DiverrTheme.radius),
        boxShadow: DiverrTheme.softShadow,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              onTap: _openProfile,
              leading: UserAvatar(name: d.ownerNome),
              title: Text(d.ownerNome, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text([
                if (d.ownerUsername != null) '@${d.ownerUsername}',
                timeAgo(d.dataHora),
              ].join(' · ')),
            ),
            InkWell(
              onTap: _openDetails,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasPhoto)
                    RemoteImage(
                      url: d.coverUrl,
                      cacheKey: d.imagens.first.id,
                      width: double.infinity,
                      height: 190,
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.diveSiteNome, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (d.profundidadeMaxima != null)
                              InfoChip(icon: Icons.arrow_downward, text: formatMeters(d.profundidadeMaxima)),
                            if (d.duracaoMinutos != null)
                              InfoChip(icon: Icons.timer_outlined, text: formatDuration(d.duracaoMinutos), color: DiverrTheme.secondary),
                          ],
                        ),
                        if (hasRatings) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 16,
                            runSpacing: 4,
                            children: [
                              _ratingChip('Local', d.notaLocal),
                              _ratingChip('Experiência', d.notaExperiencia),
                            ],
                          ),
                        ],
                        if (d.observacoes != null && d.observacoes!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            d.observacoes!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: ReactionBar(
                logId: d.id,
                summary: _social,
                onChanged: (s) => setState(() => _social = s),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: TextButton.icon(
                onPressed: _openDetails,
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: Text(
                  _social.commentsCount == 0
                      ? 'Comentar'
                      : '${_social.commentsCount} ${_social.commentsCount == 1 ? 'comentário' : 'comentários'}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
