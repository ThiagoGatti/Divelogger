import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../features/auth/data/entitlements.dart';
import '../../features/auth/data/user_model.dart';
import '../offline/local_store.dart';
import 'token_storage.dart';

/// Sessão do usuário: token + usuário (+ permissões do plano), persistidos com segurança.
class AppSession {
  AppSession._();
  static final AppSession instance = AppSession._();

  final TokenStorage _storage = TokenStorage();

  UserModel? currentUser;
  Entitlements entitlements = Entitlements.free;
  String? accessToken;
  DateTime? _expiresAt;

  /// Incrementa quando a sessão expira (401). O app escuta isso e volta para a tela inicial.
  final ValueNotifier<int> sessionExpired = ValueNotifier<int>(0);

  /// Incrementa quando usuário/plano mudam (ex.: GET /api/me). Telas escutam para se redesenhar.
  final ValueNotifier<int> changed = ValueNotifier<int>(0);

  /// Há sessão salva no aparelho. Um token vencido NÃO desloga: o app continua abrindo offline com os
  /// dados salvos. Quando voltar a internet, a primeira chamada recebe 401 e o app pede novo login
  /// (a fila de mergulhos pendentes é preservada).
  bool get isLoggedIn => accessToken != null && currentUser != null;

  /// Token já vencido (informativo).
  bool get tokenExpired => _isExpired;

  bool get isAdmin => currentUser?.isAdmin ?? false;

  bool get isPremium => entitlements.isPremium;

  bool get _isExpired =>
      _expiresAt != null && DateTime.now().isAfter(_expiresAt!);

  /// Chamar no início do app (antes do runApp).
  Future<void> restore() async {
    final saved = await _storage.read();
    if (saved.token == null || saved.userJson == null) return;

    try {
      currentUser = UserModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(saved.userJson!) as Map),
      );
      accessToken = saved.token;
      _expiresAt = saved.expiresAt;

      // permissões do plano da última vez que o servidor respondeu (para funcionar offline)
      final raw = await LocalStore.readJson('entitlements_${currentUser!.id}.json');
      if (raw is Map) entitlements = Entitlements.fromJson(Map<String, dynamic>.from(raw));
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
    entitlements = Entitlements.free;
    // Margem de 30s para não usar um token quase vencendo.
    _expiresAt = DateTime.now().add(Duration(seconds: expiresInSeconds - 30));
    await _storage.save(
      token: token,
      expiresAt: _expiresAt!,
      userJson: jsonEncode(user.toJson()),
    );
    changed.value++;
  }

  /// Atualiza usuário e permissões com o que o servidor diz AGORA.
  Future<void> updateFromMe(UserModel user, Entitlements e) async {
    currentUser = user;
    entitlements = e;
    await LocalStore.writeJson('entitlements_${user.id}.json', e.toJson());
    if (accessToken != null && _expiresAt != null) {
      await _storage.save(
        token: accessToken!,
        expiresAt: _expiresAt!,
        userJson: jsonEncode(user.toJson()),
      );
    }
    changed.value++;
  }

  Future<void> signOut() async {
    accessToken = null;
    currentUser = null;
    entitlements = Entitlements.free;
    _expiresAt = null;
    await _storage.clear();
    changed.value++;
  }

  /// Chamado pelo ApiClient ao receber 401.
  Future<void> expire() async {
    await signOut();
    sessionExpired.value++;
  }
}
