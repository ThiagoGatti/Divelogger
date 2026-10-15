import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';
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
}
