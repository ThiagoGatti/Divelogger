import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ui/widgets.dart';
import '../../auth/data/user_model.dart';
import '../data/admin_api.dart';

/// Painel do ADMIN: lista usuários e concede/remove o plano Premium
/// (enquanto não há pagamento in-app).
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _api = AdminApi();
  List<UserModel> _users = [];
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
      final users = await _api.listUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
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

  List<UserModel> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _users;
    return _users
        .where((u) => u.nomeCompleto.toLowerCase().contains(q) || u.email.toLowerCase().contains(q))
        .toList();
  }

  String _isoDate(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

  Future<void> _setPlan(UserModel user, String plano, {int? days}) async {
    try {
      final expires = days == null ? null : _isoDate(DateTime.now().add(Duration(days: days)));
      final updated = await _api.updatePlan(user.id, plano, expiresAt: expires);
      if (!mounted) return;
      setState(() {
        final i = _users.indexWhere((u) => u.id == updated.id);
        if (i >= 0) _users[i] = updated;
      });
      showSnack(context, 'Plano de ${updated.nomeCompleto} atualizado para $plano.');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Usuários e planos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou e-mail',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: const [SkeletonList(count: 5, height: 72)],
                    )
                  : _error != null
                      ? ListView(
                          padding: const EdgeInsets.all(20),
                          children: [ErrorState(message: _error!, onRetry: _load)],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final u = items[i];
                            final premium = u.plano == 'PREMIUM';
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                                leading: CircleAvatar(
                                  backgroundColor: DiverrTheme.ocean.withOpacity(.35),
                                  child: Text(
                                    initialsOf(u.nomeCompleto),
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: DiverrTheme.primary),
                                  ),
                                ),
                                title: Text(u.nomeCompleto, style: const TextStyle(fontWeight: FontWeight.w800)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u.email, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      children: [
                                        PlanBadge(premium: premium),
                                        if (u.isAdmin)
                                          const InfoChip(icon: Icons.shield_outlined, text: 'ADMIN', color: DiverrTheme.primary),
                                        if (premium && u.planExpiresAt != null)
                                          InfoChip(text: 'até ${u.planExpiresAt}', color: DiverrTheme.muted),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'p30') _setPlan(u, 'PREMIUM', days: 30);
                                    if (v == 'p365') _setPlan(u, 'PREMIUM', days: 365);
                                    if (v == 'pforever') _setPlan(u, 'PREMIUM');
                                    if (v == 'free') _setPlan(u, 'FREE');
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'p30', child: Text('Premium por 30 dias')),
                                    PopupMenuItem(value: 'p365', child: Text('Premium por 1 ano')),
                                    PopupMenuItem(value: 'pforever', child: Text('Premium sem expiração')),
                                    PopupMenuItem(value: 'free', child: Text('Voltar para Free')),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
