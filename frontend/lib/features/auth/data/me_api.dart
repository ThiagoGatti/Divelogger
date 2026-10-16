import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';
import 'entitlements.dart';
import 'user_model.dart';

class MeApi {
  final ApiClient _api;
  MeApi({ApiClient? api}) : _api = api ?? ApiClient();

  /// Busca role/plano/limites atuais. Falhas de rede são ignoradas (usa o que já tem).
  Future<void> refresh() async {
    try {
      final json = await _api.get('/api/me');
      final user = UserModel.fromJson(Map<String, dynamic>.from(json['user'] as Map));
      final ent = Entitlements.fromJson(Map<String, dynamic>.from(json['entitlements'] as Map));
      await AppSession.instance.updateFromMe(user, ent);
    } on ApiException {
      // 401 já derruba a sessão no ApiClient; demais erros (offline/500) mantêm o estado atual.
    } catch (_) {}
  }

  /// Altera só o que for informado. Lança ApiException (ex.: 409 usuário já em uso).
  Future<void> updateProfile({String? username, String? bio, String? diveVisibility}) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (bio != null) body['bio'] = bio;
    if (diveVisibility != null) body['diveVisibility'] = diveVisibility;

    final json = await _api.patch('/api/me/profile', body);
    final user = UserModel.fromJson(Map<String, dynamic>.from(json['user'] as Map));
    final ent = Entitlements.fromJson(Map<String, dynamic>.from(json['entitlements'] as Map));
    await AppSession.instance.updateFromMe(user, ent);
  }
}
