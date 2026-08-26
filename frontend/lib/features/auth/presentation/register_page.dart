import 'package:flutter/material.dart';
import '../../../core/session/session.dart';
import '../data/auth_api.dart';
import '../../home/presentation/home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _api = AuthApi();
  bool _loading = false;
  bool _terms = false;

  @override void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _register() async {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty || _password.text.length < 6 || !_terms) {
      _show('Preencha os dados e aceite os termos. A senha deve ter ao menos 6 caracteres.'); return;
    }
    setState(() => _loading = true);
    try {
      final user = await _api.register(nomeCompleto: _name.text.trim(), email: _email.text.trim(), senha: _password.text, aceitouTermosUso: true, aceitouPoliticaPrivacidade: true);
      AppSession.instance.currentUser = user;
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (_) => false);
    } catch (e) { if (mounted) _show(e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  void _show(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Criar conta')),
    body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 32), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Comece seu diário de mergulhos', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8), const Text('Crie sua conta e comece a registrar suas experiências.'), const SizedBox(height: 28),
      _field('Nome completo', _name, Icons.person_outline, 'Seu nome'), const SizedBox(height: 16),
      _field('E-mail', _email, Icons.email_outlined, 'seu@email.com'), const SizedBox(height: 16),
      _field('Senha', _password, Icons.lock_outline, 'Mínimo 6 caracteres', obscure: true), const SizedBox(height: 10),
      CheckboxListTile(value: _terms, onChanged: (v) => setState(() => _terms = v ?? false), contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, title: const Text('Aceito os termos de uso e a política de privacidade.')),
      const SizedBox(height: 18),
      SizedBox(width: double.infinity, height: 54, child: ElevatedButton(onPressed: _loading ? null : _register, child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Criar minha conta'))),
    ]))),
  );

  Widget _field(String label, TextEditingController controller, IconData icon, String hint, {bool obscure = false}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8), TextField(controller: controller, obscureText: obscure, decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)))]);
}
