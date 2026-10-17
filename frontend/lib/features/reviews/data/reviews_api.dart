import '../../../core/network/api_client.dart';
import 'review_models.dart';

class ReviewsApi {
  final ApiClient _api;
  ReviewsApi({ApiClient? api}) : _api = api ?? ApiClient();

  Future<ReviewsResult> list(String siteId) async =>
      ReviewsResult.fromJson(await _api.get('/api/site-reviews/$siteId'));

  Future<ReviewsResult> saveMine(String siteId, double rating, String? texto) async =>
      ReviewsResult.fromJson(
        await _api.put('/api/site-reviews/$siteId/me', {'rating': rating, 'texto': texto}),
      );

  Future<ReviewsResult> deleteMine(String siteId) async =>
      ReviewsResult.fromJson(await _api.deleteJson('/api/site-reviews/$siteId/me'));

  /// Moderação (autor ou ADMIN).
  Future<ReviewsResult> deleteAny(String siteId, String reviewId) async =>
      ReviewsResult.fromJson(await _api.deleteJson('/api/site-reviews/$siteId/$reviewId'));
}
