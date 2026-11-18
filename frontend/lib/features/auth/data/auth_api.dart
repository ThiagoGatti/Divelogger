import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/offline/sync_service.dart';
import 'me_api.dart';
import 'user_model.dart';

class AuthApi {
  final ApiClient _api;
  AuthApi({ApiClient? api}) : _api = api ?? ApiClient();

  /// Faz login, guarda o token e retorna o usuário.
  Future<UserModel> login(String email, String senha) async {
    final json = await _api.post(
      '/api/auth/login',
      {'email': email, 'senha': senha},
      auth: false,
    );

    final token = json['accessToken'] as String?;
    final userJson = json['user'];
    if (token == null || userJson is! Map) {
      throw ApiException('Resposta de login inválida.');
    }

    final user = UserModel.fromJson(Map<String, dynamic>.from(userJson));
    await AppSession.instance.signIn(
      token: token,
      expiresInSeconds: (json['expiresIn'] as num?)?.toInt() ?? 3600,
      user: user,
    );
    await MeApi(api: _api).refresh();
    SyncService.instance.scheduleSync(); // envia mergulhos feitos offline
    return AppSession.instance.currentUser ?? user;
  }

  /// Cria a conta e já entra (o backend de cadastro não devolve token).
  Future<UserModel> register({
    required String nomeCompleto,
    required String email,
    required String senha,
    String? telefone,
    String? dataNascimento,
    bool aceitouTermosUso = true,
    bool aceitouPoliticaPrivacidade = true,
  }) async {
    await _api.post(
      '/api/users',
      {
        'nomeCompleto': nomeCompleto,
        'email': email,
        'telefone': telefone,
        'senha': senha,
        'documento': null,
        'dataNascimento': dataNascimento,
        'aceitouTermosUso': aceitouTermosUso,
        'aceitouPoliticaPrivacidade': aceitouPoliticaPrivacidade,
      },
      auth: false,
    );
    return login(email, senha);
  }

  /// Pede o código de recuperação por e-mail. A resposta é sempre a mesma (não revela se o e-mail existe).
  Future<void> forgotPassword(String email) async {
    await _api.post('/api/auth/forgot-password', {'email': email.trim()}, auth: false);
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _api.post(
      '/api/auth/reset-password',
      {'email': email.trim(), 'code': code.trim(), 'newPassword': newPassword},
      auth: false,
    );
  }

  /// Login com Google: o servidor valida o ID token. Contas novas exigem [acceptedTerms].
  Future<UserModel> loginWithGoogle(String idToken, {bool acceptedTerms = false}) async {
    final json = await _api.post(
      '/api/auth/google',
      {'idToken': idToken, 'acceptedTerms': acceptedTerms},
      auth: false,
    );

    final token = json['accessToken'] as String?;
    final userJson = json['user'];
    if (token == null || userJson is! Map) {
      throw ApiException('Resposta de login inválida.');
    }

    final user = UserModel.fromJson(Map<String, dynamic>.from(userJson));
    await AppSession.instance.signIn(
      token: token,
      expiresInSeconds: (json['expiresIn'] as num?)?.toInt() ?? 3600,
      user: user,
    );
    await MeApi(api: _api).refresh();
    SyncService.instance.scheduleSync();
    return AppSession.instance.currentUser ?? user;
  }
}
