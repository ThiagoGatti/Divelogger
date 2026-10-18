import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/ui/widgets.dart';
import '../../admin/presentation/admin_users_page.dart';
import '../../operators/presentation/operators_page.dart';
import '../../auth/data/me_api.dart';
import '../../auth/data/user_model.dart';
import '../../landing/presentation/landing_page.dart';

/// Perfil, privacidade, plano e conta.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _api = MeApi();
  late final TextEditingController _username =
      TextEditingController(text: AppSession.instance.currentUser?.username ?? '');
  late final TextEditingController _bio =
      TextEditingController(text: AppSession.instance.currentUser?.bio ?? '');
  late String _visibility = AppSession.instance.currentUser?.diveVisibility ?? 'FOLLOWERS';
  bool _saving = false;

  static const _visibilityHelp = {
    'PRIVATE': 'Ninguém além de você vê seus mergulhos.',
    'FRIENDS': 'Só quem você segue e que também te segue de volta (amigos).',
    'FOLLOWERS': 'Qualquer pessoa que te segue vê seus mergulhos, como no Letterboxd. (padrão)',
    'PUBLIC': 'Qualquer usuário do Diverr pode ver seus mergulhos.',
  };

  @override
  void dispose() {
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final username = _username.text.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(username)) {
      showSnack(context, 'Usuário: 3 a 20 caracteres, só letras minúsculas, números ou _.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.updateProfile(
        username: username,
        bio: _bio.text.trim(),
        diveVisibility: _visibility,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      showSnack(context, 'Perfil atualizado!');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSnack(context, e.message, error: true);
    }
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(
      context,
      title: 'Sair da conta?',
      message: 'Você precisará entrar novamente para acessar seus mergulhos.',
      confirmLabel: 'Sair',
    );
    if (!ok) return;

    await AppSession.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSession.instance;
    final user = session.currentUser;
    final ent = session.entitlements;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          const SectionTitle('Perfil'),
          TextField(
            controller: _username,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Nome de usuário',
              prefixText: '@',
              helperText: 'Como outros mergulhadores vão te encontrar',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _bio,
            maxLength: 300,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Bio', alignLabelWithHint: true, hintText: 'Fale um pouco sobre você e seus mergulhos'),
          ),
          const SectionTitle('Quem pode ver meus mergulhos'),
          for (final entry in kVisibilityLabels.entries)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: RadioListTile<String>(
                value: entry.key,
                groupValue: _visibility,
                onChanged: (v) => setState(() => _visibility = v ?? _visibility),
                title: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(_visibilityHelp[entry.key] ?? ''),
              ),
            ),
          const SizedBox(height: 12),
          LoadingButton(loading: _saving, onPressed: _save, label: 'Salvar alterações', icon: Icons.check),

          const SectionTitle('Plano'),
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
                      PlanBadge(premium: ent.isPremium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ent.isPremium
                        ? (user?.planExpiresAt != null
                            ? 'Válido até ${_prettyDate(user!.planExpiresAt!)}.'
                            : 'Sem data de expiração.')
                        : 'Mergulhos ilimitados, até ${ent.maxPhotosPerLog} fotos por mergulho e informações básicas dos locais.',
                    style: const TextStyle(color: DiverrTheme.muted, height: 1.4),
                  ),
                  if (!ent.isPremium) ...[
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

          if (session.isAdmin) ...[
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
            Card(
              child: ListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OperatorsPage()),
                ),
                leading: const Icon(Icons.storefront_outlined, color: DiverrTheme.primary),
                title: const Text('Operadoras', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Cadastrar operadoras e vincular aos locais'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Para cadastrar, editar ou desativar locais, use a aba Sites.',
              style: TextStyle(color: DiverrTheme.muted, fontSize: 12.5),
            ),
          ],

          const SizedBox(height: 22),
          Card(
            child: ListTile(
              onTap: _logout,
              leading: const Icon(Icons.logout, color: DiverrTheme.danger),
              title: const Text('Sair', style: TextStyle(fontWeight: FontWeight.w700, color: DiverrTheme.danger)),
            ),
          ),
        ],
      ),
    );
  }

  static String _prettyDate(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? iso : formatDate(d);
  }
}
