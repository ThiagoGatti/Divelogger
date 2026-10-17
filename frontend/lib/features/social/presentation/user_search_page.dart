import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/ui/widgets.dart';
import '../data/social_api.dart';
import '../data/social_models.dart';
import 'public_profile_page.dart';
import 'social_widgets.dart';

/// Busca de mergulhadores por nome ou @usuário, com botão de seguir.
class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final _api = SocialApi();
  Timer? _debounce;
  String _query = '';
  List<UserSummary> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _query = value;
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> _search() async {
    final q = _query.trim();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _api.search(q);
      if (!mounted || q != _query.trim()) return; // ignora resposta de busca antiga
      setState(() {
        _results = r;
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
      appBar: AppBar(title: const Text('Encontrar mergulhadores')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              autofocus: true,
              onChanged: _onChanged,
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou @usuário',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: SkeletonList(count: 4, height: 72))
                : _error != null
                    ? Padding(padding: const EdgeInsets.all(20), child: ErrorState(message: _error!, onRetry: _search))
                    : _query.trim().length < 2
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: EmptyState(
                              icon: Icons.person_search_outlined,
                              title: 'Procure por pessoas',
                              message: 'Digite pelo menos 2 letras do nome ou do @usuário.',
                            ),
                          )
                        : _results.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: EmptyState(
                                  icon: Icons.search_off,
                                  title: 'Ninguém encontrado',
                                  message: 'Confira a grafia ou tente outro nome.',
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                itemCount: _results.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (_, i) {
                                  final u = _results[i];
                                  return UserTile(
                                    user: u,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => PublicProfilePage(userId: u.id)),
                                    ),
                                    trailing: FollowButton(
                                      userId: u.id,
                                      iFollow: u.iFollow,
                                      followsMe: u.followsMe,
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
