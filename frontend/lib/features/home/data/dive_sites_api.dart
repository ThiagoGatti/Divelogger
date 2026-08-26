import '../../../core/network/api_client.dart';
import 'dive_site_model.dart';

class DiveSitesApi {
  final ApiClient _api;
  DiveSitesApi({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<DiveSiteModel>> findAll() async {
    final data = await _api.getList('/api/dive-sites');
    return data.map((e) => DiveSiteModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}
