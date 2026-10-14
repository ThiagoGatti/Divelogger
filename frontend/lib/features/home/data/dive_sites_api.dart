import '../../../core/network/api_client.dart';
import 'dive_site_model.dart';

class DiveSitesApi {
  final ApiClient _api;

  DiveSitesApi({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<DiveSiteModel>> findAll() async {
    final data = await _api.getList('/api/dive-sites');
    return data
        .map((e) => DiveSiteModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<DiveSiteModel> create({
    required String nome,
    String? descricao,
    required String pais,
    String? estado,
    String? cidade,
    required double latitude,
    required double longitude,
    double? profundidadeMaxima,
    String? tipo,
  }) async {
    final json = await _api.post(
      '/api/dive-sites',
      {
        'nome': nome,
        'descricao': descricao,
        'pais': pais,
        'estado': estado,
        'cidade': cidade,
        'latitude': latitude,
        'longitude': longitude,
        'profundidadeMaxima': profundidadeMaxima,
        'tipo': tipo,
      },
    );

    return DiveSiteModel.fromJson(json);
  }
}