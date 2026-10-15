import '../../../core/network/api_client.dart';
import '../../auth/data/user_model.dart';

class AdminApi {
  final ApiClient _api;
  AdminApi({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<UserModel>> listUsers() async {
    final data = await _api.getList('/api/admin/users');
    return data
        .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// [expiresAt] no formato yyyy-MM-dd (só vale para PREMIUM; null = sem expiração).
  Future<UserModel> updatePlan(int userId, String plano, {String? expiresAt}) async {
    final json = await _api.patch(
      '/api/admin/users/$userId/plan',
      {'plano': plano, 'planExpiresAt': expiresAt},
    );
    return UserModel.fromJson(json);
  }
}
