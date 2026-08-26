import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/session/session.dart';
import '../data/auth_api.dart';
import 'register_page.dart';
import '../../home/presentation/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _api = AuthApi();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      _show('Informe e-mail e senha.');
      return;
    }
    setState(() => _loading = true);
    try {
      final user = await _api.login(_email.text.trim(), _password.text);
      AppSession.instance.currentUser = user;
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (_) => false);
    } catch (e) {
      if (mounted) _show(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Center(child: Icon(Icons.scuba_diving, size: 76, color: DiverrTheme.primary)),
            const SizedBox(height: 28),
            Text('Bem-vindo de volta!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: DiverrTheme.dark)),
            const SizedBox(height: 8),
            Text('Entre para acessar seus mergulhos e explorar novos lugares.', style: TextStyle(color: Colors.grey.shade600, height: 1.4)),
            const SizedBox(height: 28),
            _field('E-mail', _email, Icons.email_outlined, keyboard: TextInputType.emailAddress),
            const SizedBox(height: 16),
            Text('Senha', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: 'Digite sua senha', prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)),
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(width: double.infinity, height: 54, child: ElevatedButton(onPressed: _loading ? null : _login, child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Entrar'))),
            const SizedBox(height: 12),
            Center(child: TextButton(onPressed: () {}, child: const Text('Esqueci minha senha'))),
            const Divider(height: 32),
            Center(child: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())), child: const Text('Ainda não tenho uma conta'))),
          ]),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, IconData icon, {TextInputType? keyboard}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8),
    TextField(controller: controller, keyboardType: keyboard, decoration: InputDecoration(hintText: 'seu@email.com', prefixIcon: Icon(icon))),
  ]);
}
