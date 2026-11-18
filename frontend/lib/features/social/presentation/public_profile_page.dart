import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ui/widgets.dart';
import '../../auth/data/user_model.dart';
import '../../dive_logs/data/dive_log_model.dart';
import '../../home/presentation/dive_logs_page.dart';
import '../../lists/data/list_models.dart';
import '../../lists/presentation/list_details_page.dart';
import '../data/social_api.dart';
import '../data/social_models.dart';
import 'favorites_section.dart';
import 'follow_list_page.dart';
import 'social_widgets.dart';

/// Perfil de outro usuário: dados públicos, favoritos e, se a privacidade permitir, mergulhos e listas.
class PublicProfilePage extends StatefulWidget {
  final int userId;
  const PublicProfilePage({super.key, required this.userId});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  final _api = SocialApi();
  PublicProfile? _profile;
  List<DiveLogModel> _logs = [];
  List<ListSummary> _lists = [];
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
      final p = await _api.profile(widget.userId);
      var logs = <DiveLogModel>[];
      var lists = <ListSummary>[];
      if (p.canViewDives) {
        final results = await Future.wait([_api.userDiveLogs(p.id), _api.userLists(p.id)]);
        logs = results[0] as List<DiveLogModel>;
        lists = results[1] as List<ListSummary>;
      }
      if (!mounted) return;
      setState(() {
        _profile = p;
        _logs = logs;
        _lists = lists;
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

  void _openList(FollowListMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FollowListPage(userId: widget.userId, mode: mode)),
    );
  }

  String _lockedMessage(PublicProfile p) {
    switch (p.diveVisibility) {
      case 'PRIVATE':
        return '${p.nomeCompleto} não compartilha os mergulhos com ninguém.';
      case 'FRIENDS':
        return 'Os mergulhos de ${p.nomeCompleto} são visíveis apenas para amigos '
            '(quem se segue mutuamente). Siga e seja seguido de volta para ver.';
      default:
        return 'Os mergulhos de ${p.nomeCompleto} são visíveis apenas para quem o segue. '
            'Siga para ver.';
    }
  }

  Widget _count(String value, String label, VoidCallback onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(fontSize: 12, color: DiverrTheme.muted)),
              ],
            ),
          ),
        ),
      );

  Widget _header(PublicProfile p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(name: p.nomeCompleto, radius: 32, photoUrl: p.photoUrl, photoId: p.photoId),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nomeCompleto, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    if (p.username != null) Text('@${p.username}', style: const TextStyle(color: DiverrTheme.muted)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (p.isFriend)
                          const InfoChip(icon: Icons.people_alt_outlined, text: 'Amigos', color: DiverrTheme.success)
                        else if (p.followsMe)
                          const InfoChip(text: 'Segue você', color: DiverrTheme.muted),
                        InfoChip(icon: Icons.visibility_outlined, text: kVisibilityLabels[p.diveVisibility] ?? '', color: DiverrTheme.secondary),
                      ],
                    ),
                  ],
                ),
              ),
              if (!p.self)
                FollowButton(
                  userId: p.id,
                  iFollow: p.iFollow,
                  followsMe: p.followsMe,
                  onChanged: (_) => _load(), // seguir muda o que posso ver
                ),
            ],
          ),
          if (p.bio != null && p.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(p.bio!, style: const TextStyle(height: 1.4)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _count('${p.followers}', 'Seguidores', () => _openList(FollowListMode.followers)),
              _count('${p.following}', 'Seguindo', () => _openList(FollowListMode.following)),
              _count('${p.friends}', 'Amigos', () => _openList(FollowListMode.friends)),
              if (p.divesCount != null)
                Expanded(
                  child: Column(
                    children: [
                      Text('${p.divesCount}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      const Text('Mergulhos', style: TextStyle(fontSize: 12, color: DiverrTheme.muted)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          FavoritesSection(userId: p.id, editable: false),
        ],
      ),
    );
  }

  Widget _listsView() {
    if (_lists.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          EmptyState(
            icon: Icons.format_list_numbered,
            title: 'Nenhuma lista',
            message: 'Esta pessoa ainda não criou listas.',
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        for (final l in _lists)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ImageSideCard(
              imageUrl: l.coverUrl,
              cacheKey: l.coverImageId,
              placeholderIcon: Icons.format_list_numbered,
              imageWidth: 86,
              minHeight: 86,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ListDetailsPage(listId: l.id, initialTitle: l.nome, readOnly: true),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;

    return Scaffold(
      appBar: AppBar(title: Text(p?.username != null ? '@${p!.username}' : 'Perfil')),
      body: _loading
          ? const Padding(padding: EdgeInsets.all(20), child: SkeletonList(count: 3, height: 110))
          : _error != null
              ? Padding(padding: const EdgeInsets.all(20), child: ErrorState(message: _error!, onRetry: _load))
              : p!.canViewDives
                  ? DefaultTabController(
                      length: 2,
                      child: NestedScrollView(
                        headerSliverBuilder: (context, _) => [
                          SliverToBoxAdapter(child: _header(p)),
                          const SliverToBoxAdapter(
                            child: TabBar(
                              labelColor: DiverrTheme.primary,
                              unselectedLabelColor: DiverrTheme.muted,
                              indicatorColor: DiverrTheme.primary,
                              labelStyle: TextStyle(fontWeight: FontWeight.w800),
                              tabs: [Tab(text: 'Mergulhos'), Tab(text: 'Listas')],
                            ),
                          ),
                        ],
                        body: TabBarView(
                          children: [
                            DiveLogsTab(logs: _logs, loading: false, error: null, onRefresh: _load, readOnly: true),
                            _listsView(),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        _header(p),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                          child: EmptyState(
                            icon: Icons.lock_outline,
                            title: 'Mergulhos protegidos',
                            message: _lockedMessage(p),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
