import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../features/auth/data/user_model.dart';
import 'token_storage.dart';

/// Sessão do usuário: token + usuário, persistidos com segurança.
class AppSession {
  AppSession._();
  static final AppSession instance = AppSession._();

  final TokenStorage _storage = TokenStorage();

  UserModel? currentUser;
  String? accessToken;
  DateTime? _expiresAt;

  /// Incrementa quando a sessão expira (401). O app escuta isso e volta para a tela inicial.
  final ValueNotifier<int> sessionExpired = ValueNotifier<int>(0);

  bool get isLoggedIn =>
      accessToken != null && currentUser != null && !_isExpired;

  bool get isAdmin => currentUser?.isAdmin ?? false;

  bool get _isExpired =>
      _expiresAt != null && DateTime.now().isAfter(_expiresAt!);

  /// Chamar no início do app (antes do runApp).
  Future<void> restore() async {
    final saved = await _storage.read();
    if (saved.token == null || saved.userJson == null) return;

    if (saved.expiresAt != null && DateTime.now().isAfter(saved.expiresAt!)) {
      await _storage.clear();
      return;
    }

    try {
      currentUser = UserModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(saved.userJson!) as Map),
      );
      accessToken = saved.token;
      _expiresAt = saved.expiresAt;
    } catch (_) {
      await _storage.clear();
    }
  }

  Future<void> signIn({
    required String token,
    required int expiresInSeconds,
    required UserModel user,
  }) async {
    accessToken = token;
    currentUser = user;
    // Margem de 30s para não usar um token quase vencendo.
    _expiresAt = DateTime.now().add(Duration(seconds: expiresInSeconds - 30));
    await _storage.save(
      token: token,
      expiresAt: _expiresAt!,
      userJson: jsonEncode(user.toJson()),
    );
  }

  Future<void> signOut() async {
    accessToken = null;
    currentUser = null;
    _expiresAt = null;
    await _storage.clear();
  }

  /// Chamado pelo ApiClient ao receber 401.
  Future<void> expire() async {
    await signOut();
    sessionExpired.value++;
  }
}
