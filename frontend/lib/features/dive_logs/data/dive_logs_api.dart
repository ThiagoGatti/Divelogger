import '../../../core/network/api_client.dart';
import 'dive_log_model.dart';

class DiveLogsApi {
  final ApiClient _api;

  DiveLogsApi({ApiClient? api}) : _api = api ?? ApiClient();

  static DiveLogModel _one(Map<String, dynamic> json) => DiveLogModel.fromJson(json);

  /// Lista crua (JSON) dos meus mergulhos, para guardar em cache.
  Future<List<dynamic>> findMineRaw() => _api.getList('/api/dive-logs/me');

  Future<List<DiveLogModel>> findMine() async {
    final data = await _api.getList('/api/dive-logs/me');
    return data
        .map((e) => DiveLogModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<DiveLogModel>> findMineBySite(String siteId) async {
    final data = await _api.getList('/api/dive-logs/site/$siteId');
    return data
        .map((e) => DiveLogModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<DiveLogModel> findById(String id) async => _one(await _api.get('/api/dive-logs/$id'));

  Future<DiveLogModel> create(Map<String, dynamic> body) async =>
      _one(await _api.post('/api/dive-logs', body));

  Future<DiveLogModel> update(String id, Map<String, dynamic> body) async =>
      _one(await _api.put('/api/dive-logs/$id', body));

  Future<void> delete(String id) => _api.delete('/api/dive-logs/$id');

  Future<DiveLogModel> removeImage(String logId, String imageId) async =>
      _one(await _api.deleteJson('/api/dive-logs/$logId/images/$imageId'));
}
