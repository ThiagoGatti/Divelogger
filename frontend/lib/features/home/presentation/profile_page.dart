import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/session/session.dart';
import '../../../core/ui/widgets.dart';
import '../../admin/presentation/admin_users_page.dart';
import '../../auth/data/me_api.dart';
import '../../landing/presentation/landing_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      title: 'Sair da conta?',
      message: 'Você precisará entrar novamente para acessar seus mergulhos.',
      confirmLabel: 'Sair',
    );
    if (!ok) return;

    await AppSession.instance.signOut();
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppSession.instance.changed,
      builder: (context, _, __) {
        final session = AppSession.instance;
        final user = session.currentUser;
        final ent = session.entitlements;

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () => MeApi().refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
              children: [
                const PageHeader(title: 'Perfil'),

                // ---------- identidade
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: DiverrTheme.oceanGradient,
                    borderRadius: BorderRadius.circular(DiverrTheme.radius + 4),
                    boxShadow: DiverrTheme.softShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        child: Text(
                          initialsOf(user?.nomeCompleto ?? ''),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.nomeCompleto ?? 'Mergulhador',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user?.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 10),
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ---------- plano
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              ent.isPremium ? Icons.workspace_premium : Icons.lock_open_outlined,
                              color: ent.isPremium ? DiverrTheme.gold : DiverrTheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ent.isPremium ? 'Premium ativo' : 'Plano Free',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (ent.isPremium) ...[
                          Text(
                            user?.planExpiresAt != null
                                ? 'Válido até ${_prettyDate(user!.planExpiresAt!)}.'
                                : 'Sem data de expiração.',
                            style: const TextStyle(color: DiverrTheme.muted),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Mergulhos ilimitados · até ${ent.maxPhotosPerLog} fotos por mergulho · estatísticas avançadas',
                            style: const TextStyle(color: DiverrTheme.muted, height: 1.4),
                          ),
                        ] else ...[
                          if (ent.maxDiveLogs != null) ...[
                            Text(
                              '${ent.diveLogsUsed} de ${ent.maxDiveLogs} mergulhos usados',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: (ent.diveLogsUsed / ent.maxDiveLogs!).clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: DiverrTheme.ocean.withOpacity(.3),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Text(
                            'Até ${ent.maxPhotosPerLog} fotos por mergulho e estatísticas básicas.',
                            style: const TextStyle(color: DiverrTheme.muted),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () => showUpgradeSheet(context),
                            icon: const Icon(Icons.workspace_premium),
                            label: const Text('Conhecer o Premium'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ---------- admin
                if (session.isAdmin) ...[
                  const SizedBox(height: 22),
                  const SectionTitle('Administração'),
                  Card(
                    child: ListTile(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminUsersPage()),
                      ),
                      leading: const Icon(Icons.manage_accounts_outlined, color: DiverrTheme.primary),
                      title: const Text('Usuários e planos', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Conceder ou remover o Premium'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Para cadastrar, editar ou desativar locais, use a aba Sites.',
                      style: TextStyle(color: DiverrTheme.muted, fontSize: 12.5),
                    ),
                  ),
                ],

                const SizedBox(height: 22),
                Card(
                  child: ListTile(
                    onTap: () => _logout(context),
                    leading: const Icon(Icons.logout, color: DiverrTheme.danger),
                    title: const Text('Sair', style: TextStyle(fontWeight: FontWeight.w700, color: DiverrTheme.danger)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _prettyDate(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? iso : formatDate(d);
  }
}
