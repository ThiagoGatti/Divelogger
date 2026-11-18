import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ui/widgets.dart';
import '../../home/presentation/home_page.dart';
import '../../legal/legal_page.dart';
import '../data/auth_api.dart';

/// Configuração do login com Google. O "Web client ID" do Google Cloud entra na hora de gerar o app:
///   --dart-define=GOOGLE_SERVER_CLIENT_ID=...   (ou nos arquivos env/*.json)
/// Sem ele, o botão não aparece.
class GoogleConfig {
  GoogleConfig._();

  static const String serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  static bool get enabled => serverClientId.isNotEmpty && !serverClientId.startsWith('COLE_');
}

/// "ou" + botão "Continuar com o Google" (login e cadastro).
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _busy = false;

  Future<bool> _askTerms() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Criar sua conta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Para criar a conta com o Google, você precisa aceitar os Termos de Uso e a Política de Privacidade.'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).push(LegalPage.terms()),
              child: const Text('Ler Termos de Uso'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).push(LegalPage.privacy()),
              child: const Text('Ler Política de Privacidade'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Aceitar e continuar'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final google = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: GoogleConfig.serverClientId,
      );
      try {
        await google.signOut(); // sempre mostra o seletor de contas
      } catch (_) {}

      final account = await google.signIn();
      if (account == null) {
        if (mounted) setState(() => _busy = false);
        return; // o usuário cancelou
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw ApiException('O Google não devolveu o token de acesso. Tente novamente.');
      }

      final api = AuthApi();
      try {
        await api.loginWithGoogle(idToken);
      } on ApiException catch (e) {
        if (e.code != 'TERMS_REQUIRED') rethrow;
        if (!mounted) return;
        final accepted = await _askTerms();
        if (!accepted) {
          if (mounted) setState(() => _busy = false);
          return;
        }
        await api.loginWithGoogle(idToken, acceptedTerms: true);
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, e.message, error: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(
        context,
        'Não foi possível entrar com o Google. Verifique a configuração do app e tente de novo.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!GoogleConfig.enabled) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('ou', style: TextStyle(color: DiverrTheme.muted.withOpacity(.9))),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _busy ? null : _signIn,
          style: OutlinedButton.styleFrom(
            foregroundColor: context.strongText,
            side: BorderSide(color: DiverrTheme.muted.withOpacity(.5)),
          ),
          icon: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Text(
                    'G',
                    style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4285F4), fontSize: 15),
                  ),
                ),
          label: const Text('Continuar com o Google'),
        ),
      ],
    );
  }
}
