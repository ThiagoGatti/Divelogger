import '../../../core/network/api_client.dart';
import '../../dive_logs/data/dive_log_model.dart';
import '../../lists/data/list_models.dart';
import 'social_models.dart';

class SocialApi {
  final ApiClient _api;
  SocialApi({ApiClient? api}) : _api = api ?? ApiClient();

  List<T> _list<T>(List<dynamic> data, T Function(Map<String, dynamic>) f) =>
      data.map((e) => f(Map<String, dynamic>.from(e as Map))).toList();

  // ---- usuários ----

  Future<List<UserSummary>> search(String q) async => _list(
        await _api.getList('/api/users/search?q=${Uri.encodeQueryComponent(q)}'),
        UserSummary.fromJson,
      );

  Future<PublicProfile> profile(int userId) async =>
      PublicProfile.fromJson(await _api.get('/api/users/$userId/profile'));

  /// Seguir é imediato. Devolve o perfil atualizado.
  Future<PublicProfile> follow(int userId) async =>
      PublicProfile.fromJson(await _api.put('/api/users/$userId/follow', {}));

  Future<PublicProfile> unfollow(int userId) async =>
      PublicProfile.fromJson(await _api.deleteJson('/api/users/$userId/follow'));

  Future<List<UserSummary>> followers(int userId) async =>
      _list(await _api.getList('/api/users/$userId/followers'), UserSummary.fromJson);

  Future<List<UserSummary>> following(int userId) async =>
      _list(await _api.getList('/api/users/$userId/following'), UserSummary.fromJson);

  Future<List<UserSummary>> friends(int userId) async =>
      _list(await _api.getList('/api/users/$userId/friends'), UserSummary.fromJson);

  // ---- dados visíveis de outro usuário ----

  Future<List<DiveLogModel>> userDiveLogs(int userId) async =>
      _list(await _api.getList('/api/users/$userId/dive-logs'), DiveLogModel.fromJson);

  Future<List<ListSummary>> userLists(int userId) async =>
      _list(await _api.getList('/api/users/$userId/lists'), ListSummary.fromJson);

  Future<ListDetail> userFavorites(int userId) async =>
      ListDetail.fromJson(await _api.get('/api/users/$userId/favorites'));

  // ---- feed ----

  Future<FeedPage> feed({int page = 0, int size = 20}) async =>
      FeedPage.fromJson(await _api.get('/api/feed?page=$page&size=$size'));

  // ---- reações e comentários ----

  Future<SocialSummary> summary(String logId) async =>
      SocialSummary.fromJson(await _api.get('/api/dive-logs/$logId/social'));

  Future<SocialSummary> react(String logId, String emoji) async =>
      SocialSummary.fromJson(await _api.put('/api/dive-logs/$logId/reaction', {'emoji': emoji}));

  Future<SocialSummary> removeReaction(String logId) async =>
      SocialSummary.fromJson(await _api.deleteJson('/api/dive-logs/$logId/reaction'));

  Future<List<CommentModel>> comments(String logId) async =>
      _list(await _api.getList('/api/dive-logs/$logId/comments'), CommentModel.fromJson);

  Future<List<CommentModel>> addComment(String logId, String texto) async {
    // o backend devolve a lista atualizada de comentários
    final json = await _api.postList('/api/dive-logs/$logId/comments', {'texto': texto});
    return _list(json, CommentModel.fromJson);
  }

  Future<List<CommentModel>> deleteComment(String logId, String commentId) async {
    final json = await _api.deleteList('/api/dive-logs/$logId/comments/$commentId');
    return _list(json, CommentModel.fromJson);
  }
}
