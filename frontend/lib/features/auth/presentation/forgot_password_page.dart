import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ui/widgets.dart';
import '../data/auth_api.dart';

/// Recuperação de senha em 2 passos: (1) e-mail -> recebe um código de 6 dígitos; (2) código + nova senha.
class ForgotPasswordPage extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _api = AuthApi();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  int _step = 0;
  bool _loading = false;
  bool _obscure = true;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  bool get _emailOk => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());

  Future<void> _sendCode() async {
    if (!_emailOk) {
      showSnack(context, 'Informe um e-mail válido.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await _api.forgotPassword(_email.text);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _step = 1;
      });
      _startCooldown();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showSnack(context, e.message, error: true);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _loading) return;
    try {
      await _api.forgotPassword(_email.text);
      if (!mounted) return;
      showSnack(context, 'Se o e-mail tiver uma conta, enviamos um novo código.');
      _startCooldown();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _api.resetPassword(
        email: _email.text,
        code: _code.text,
        newPassword: _password.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha redefinida! Entre com a nova senha.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Esqueci minha senha')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            if (_step == 0) ..._stepEmail() else ..._stepReset(),
          ],
        ),
      ),
    );
  }

  List<Widget> _stepEmail() => [
        const Text(
          'Informe o e-mail da sua conta. Enviaremos um código de 6 dígitos para você criar uma nova senha.',
          style: TextStyle(color: DiverrTheme.muted, height: 1.45),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined)),
          onSubmitted: (_) => _sendCode(),
        ),
        const SizedBox(height: 20),
        LoadingButton(loading: _loading, onPressed: _sendCode, label: 'Enviar código', icon: Icons.send),
      ];

  List<Widget> _stepReset() => [
        Text(
          'Enviamos um código de 6 dígitos para ${_email.text.trim()}. Ele vale por 15 minutos. '
          'Confira também a caixa de spam.',
          style: const TextStyle(color: DiverrTheme.muted, height: 1.45),
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Código de 6 dígitos',
                  prefixIcon: Icon(Icons.pin_outlined),
                  counterText: '',
                ),
                validator: (v) => (v == null || v.length != 6) ? 'Digite os 6 dígitos' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Nova senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.length < 8) return 'Use pelo menos 8 caracteres';
                  if (v.length > 72) return 'Senha muito longa';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                decoration: const InputDecoration(
                  labelText: 'Repita a nova senha',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) => v != _password.text ? 'As senhas não conferem' : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        LoadingButton(loading: _loading, onPressed: _reset, label: 'Redefinir senha', icon: Icons.check),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _cooldown > 0 ? null : _resend,
          child: Text(_cooldown > 0 ? 'Reenviar código em ${_cooldown}s' : 'Reenviar código'),
        ),
        TextButton(
          onPressed: () => setState(() => _step = 0),
          child: const Text('Usar outro e-mail'),
        ),
      ];
}
