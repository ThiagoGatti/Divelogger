import '../../../core/network/api_client.dart';
import 'user_model.dart';

class AuthApi {
  final ApiClient _api;
  AuthApi({ApiClient? api}) : _api = api ?? ApiClient();

  Future<UserModel> login(String email, String senha) async {
    final json = await _api.post('/api/auth/login', {
      'email': email,
      'senha': senha,
    });
    return UserModel.fromJson(json);
  }

  Future<UserModel> register({
    required String nomeCompleto,
    required String email,
    required String senha,
    String? telefone,
    String? dataNascimento,
    bool aceitouTermosUso = true,
    bool aceitouPoliticaPrivacidade = true,
  }) async {
    final json = await _api.post('/api/users', {
      'nomeCompleto': nomeCompleto,
      'email': email,
      'telefone': telefone,
      'senha': senha,
      'documento': null,
      'dataNascimento': dataNascimento,
      'aceitouTermosUso': aceitouTermosUso,
      'aceitouPoliticaPrivacidade': aceitouPoliticaPrivacidade,
    });
    return UserModel.fromJson(json);
  }
}
