import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/events.dart';
import '../../../core/format.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/ui/widgets.dart';
import '../../auth/data/me_api.dart';
import '../../social/data/social_api.dart';
import '../../social/data/social_models.dart';
import '../../social/presentation/favorites_section.dart';
import '../../social/presentation/follow_list_page.dart';
import '../../social/presentation/user_search_page.dart';
import '../../dive_logs/data/dive_log_model.dart';
import '../../dive_logs/data/dive_logs_repository.dart';
import '../../dive_logs/presentation/dive_log_details_page.dart';
import '../../lists/presentation/lists_tabs.dart';
import '../../profile/presentation/diary_tab.dart';
import '../../profile/presentation/settings_page.dart';
import 'activity_page.dart';
import 'dive_logs_page.dart';

/// Perfil: cabeçalho + abas Diário, Mergulhos, Quero mergulhar, Listas e Estatísticas.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<DiveLogModel> _logs = [];
  PublicProfile? _social;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _loadSocial();
    AppEvents.diveLogsChanged.addListener(_load);
    AppEvents.followsChanged.addListener(_loadSocial);
    AppEvents.listsChanged.addListener(_loadSocial);
  }

  @override
  void dispose() {
    AppEvents.diveLogsChanged.removeListener(_load);
    AppEvents.followsChanged.removeListener(_loadSocial);
    AppEvents.listsChanged.removeListener(_loadSocial);
    super.dispose();
  }

  Future<void> _load() async {
    if (!AppSession.instance.isLoggedIn) return;
    try {
      final logs = await DiveLogsRepository.instance.findMine();
      if (!mounted) return;
      setState(() {
        _logs = logs;
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

  /// Contadores (seguidores, seguindo, amigos) e total de locais (mergulhos + "Já mergulhei").
  Future<void> _loadSocial() async {
    final me = AppSession.instance.currentUser;
    if (me == null) return;
    try {
      final p = await SocialApi().profile(me.id);
      if (mounted) setState(() => _social = p);
    } on ApiException {
      // sem conexão: mantém o que já tem
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_load(), _loadSocial(), MeApi().refresh()]);
  }

  void _openFollowList(FollowListMode mode) {
    final me = AppSession.instance.currentUser;
    if (me == null) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => FollowListPage(userId: me.id, mode: mode)))
        .then((_) => _loadSocial());
  }

  Future<void> _openLast() async {
    if (_logs.isEmpty) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DiveLogDetailsPage(log: _logs.first)),
    );
    if (changed == true) _load();
  }

  Widget _header(BuildContext context) {
    final session = AppSession.instance;
    final user = session.currentUser;
    final ent = session.entitlements;
    final totalMinutes = _logs.fold<int>(0, (s, l) => s + (l.duracaoMinutos ?? 0));
    final sites = _logs.map((l) => l.diveSiteId).toSet().length;
    final last = _logs.isEmpty ? null : _logs.first;

    Widget stat(String value, String label, {VoidCallback? onTap}) => Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: DiverrTheme.oceanGradient,
              borderRadius: BorderRadius.circular(DiverrTheme.radius + 4),
              boxShadow: DiverrTheme.softShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: Text(
                        initialsOf(user?.nomeCompleto ?? ''),
                        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.nomeCompleto ?? 'Mergulhador',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          if (user?.username != null)
                            Text('@${user!.username}', style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: [
                              PlanBadge(premium: ent.isPremium),
                              if (session.isAdmin)
                                const InfoChip(icon: Icons.shield_outlined, text: 'ADMIN', color: Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const UserSearchPage()))
                          .then((_) => _loadSocial()),
                      icon: const Icon(Icons.person_search_outlined, color: Colors.white),
                      tooltip: 'Encontrar mergulhadores',
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      ),
                      icon: const Icon(Icons.settings_outlined, color: Colors.white),
                      tooltip: 'Configurações',
                    ),
                  ],
                ),
                if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(user.bio!, style: const TextStyle(color: Colors.white, height: 1.35)),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    stat('${_logs.length}', 'Mergulhos'),
                    stat('${_social?.sitesCount ?? sites}', 'Locais'),
                    stat(formatDuration(totalMinutes), 'Submerso'),
                  ],
                ),
                const SizedBox(height: 6),
                const Divider(color: Colors.white24, height: 14),
                Row(
                  children: [
                    stat('${_social?.followers ?? 0}', 'Seguidores', onTap: () => _openFollowList(FollowListMode.followers)),
                    stat('${_social?.following ?? 0}', 'Seguindo', onTap: () => _openFollowList(FollowListMode.following)),
                    stat('${_social?.friends ?? 0}', 'Amigos', onTap: () => _openFollowList(FollowListMode.friends)),
                  ],
                ),
              ],
            ),
          ),
          if (user != null) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FavoritesSection(userId: user.id, editable: true),
            ),
          ],
          if (last != null) ...[
            const SizedBox(height: 12),
            Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _openLast,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: RemoteImage(
                          url: last.coverUrl,
                          cacheKey: last.imagens.isEmpty ? null : last.imagens.first.id,
                          width: 56,
                          height: 56,
                          placeholderIcon: Icons.scuba_diving,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ÚLTIMO MERGULHO',
                              style: TextStyle(fontSize: 11, letterSpacing: .8, fontWeight: FontWeight.w900, color: DiverrTheme.muted),
                            ),
                            const SizedBox(height: 2),
                            Text(last.diveSiteNome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                            Text(formatDateTime(last.dataHora), style: const TextStyle(color: DiverrTheme.muted, fontSize: 12.5)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: DiverrTheme.muted),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppSession.instance.changed,
      builder: (context, _, __) {
        return DefaultTabController(
          length: 5,
          child: SafeArea(
            bottom: false,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(child: _header(context)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabsDelegate(
                    const TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: DiverrTheme.primary,
                      unselectedLabelColor: DiverrTheme.muted,
                      indicatorColor: DiverrTheme.primary,
                      labelStyle: TextStyle(fontWeight: FontWeight.w800),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(text: 'Diário'),
                        Tab(text: 'Mergulhos'),
                        Tab(text: 'Quero mergulhar'),
                        Tab(text: 'Listas'),
                        Tab(text: 'Estatísticas'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  DiaryTab(logs: _logs, loading: _loading, error: _error, onRefresh: _refreshAll),
                  DiveLogsTab(logs: _logs, loading: _loading, error: _error, onRefresh: _refreshAll),
                  const WishlistTab(),
                  const ListsTab(),
                  StatsTab(logs: _logs, loading: _loading, error: _error, onRefresh: _refreshAll),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabsDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: DiverrTheme.background, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabsDelegate oldDelegate) => false;
}
