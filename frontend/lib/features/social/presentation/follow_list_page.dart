import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/ui/widgets.dart';
import '../data/social_api.dart';
import '../data/social_models.dart';
import 'public_profile_page.dart';
import 'social_widgets.dart';

enum FollowListMode { followers, following, friends }

/// Seguidores, Seguindo ou Amigos de um usuário.
class FollowListPage extends StatefulWidget {
  final int userId;
  final FollowListMode mode;
  const FollowListPage({super.key, required this.userId, required this.mode});

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
  final _api = SocialApi();
  List<UserSummary> _users = [];
  bool _loading = true;
  String? _error;

  String get _title {
    switch (widget.mode) {
      case FollowListMode.followers:
        return 'Seguidores';
      case FollowListMode.following:
        return 'Seguindo';
      case FollowListMode.friends:
        return 'Amigos';
    }
  }

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
      final list = switch (widget.mode) {
        FollowListMode.followers => await _api.followers(widget.userId),
        FollowListMode.following => await _api.following(widget.userId),
        FollowListMode.friends => await _api.friends(widget.userId),
      };
      if (!mounted) return;
      setState(() {
        _users = list;
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
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: _loading
          ? const Padding(padding: EdgeInsets.all(20), child: SkeletonList(count: 5, height: 72))
          : _error != null
              ? Padding(padding: const EdgeInsets.all(20), child: ErrorState(message: _error!, onRetry: _load))
              : _users.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: EmptyState(
                        icon: Icons.group_outlined,
                        title: 'Nada por aqui ainda',
                        message: widget.mode == FollowListMode.friends
                            ? 'Amigos são pessoas que você segue e que também te seguem de volta.'
                            : 'Quando houver pessoas nesta lista, elas aparecem aqui.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final u = _users[i];
                        return UserTile(
                          user: u,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => PublicProfilePage(userId: u.id)),
                          ),
                        );
                      },
                    ),
    );
  }
}
