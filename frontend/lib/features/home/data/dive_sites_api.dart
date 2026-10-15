import '../../../core/network/api_client.dart';
import 'dive_site_model.dart';

class DiveSitesApi {
  final ApiClient _api;

  DiveSitesApi({ApiClient? api}) : _api = api ?? ApiClient();

  /// Usuário comum recebe só os ativos. ADMIN pode pedir também os inativos.
  Future<List<DiveSiteModel>> findAll({bool includeInactive = false}) async {
    final data = await _api.getList(
      includeInactive ? '/api/dive-sites?includeInactive=true' : '/api/dive-sites',
    );
    return data
        .map((e) => DiveSiteModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<DiveSiteModel> findById(String id) async {
    return DiveSiteModel.fromJson(await _api.get('/api/dive-sites/$id'));
  }

  Map<String, dynamic> _body({
    required String nome,
    String? descricao,
    required String pais,
    String? estado,
    String? cidade,
    required double latitude,
    required double longitude,
    double? profundidadeMaxima,
    String? tipo,
  }) =>
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
      };

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
      _body(
        nome: nome,
        descricao: descricao,
        pais: pais,
        estado: estado,
        cidade: cidade,
        latitude: latitude,
        longitude: longitude,
        profundidadeMaxima: profundidadeMaxima,
        tipo: tipo,
      ),
    );
    return DiveSiteModel.fromJson(json);
  }

  Future<DiveSiteModel> update(
    String id, {
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
    final json = await _api.put(
      '/api/dive-sites/$id',
      _body(
        nome: nome,
        descricao: descricao,
        pais: pais,
        estado: estado,
        cidade: cidade,
        latitude: latitude,
        longitude: longitude,
        profundidadeMaxima: profundidadeMaxima,
        tipo: tipo,
      ),
    );
    return DiveSiteModel.fromJson(json);
  }

  /// Desativar (exclusão lógica) ou reativar.
  Future<DiveSiteModel> setAtivo(String id, bool ativo) async {
    final json = await _api.patch('/api/dive-sites/$id/ativo', {'ativo': ativo});
    return DiveSiteModel.fromJson(json);
  }

  Future<DiveSiteModel> removeImage(String siteId, String imageId) async {
    return DiveSiteModel.fromJson(
      await _api.deleteJson('/api/dive-sites/$siteId/images/$imageId'),
    );
  }
}
