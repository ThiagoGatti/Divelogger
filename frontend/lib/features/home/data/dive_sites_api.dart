import '../../../core/network/api_client.dart';
import 'dive_site_model.dart';

/// Campos editáveis de um Dive Site (usado por criar e editar; somente ADMIN).
class DiveSiteInput {
  final String nome;
  final String? descricao;
  final String pais;
  final String? estado;
  final String? cidade;
  final double latitude;
  final double longitude;
  final double? profundidadeMaxima;
  final String? tipo;
  final String? nivel;

  /// Informações avançadas (Premium): chaves iguais às do backend.
  final Map<String, String?> extended;

  const DiveSiteInput({
    required this.nome,
    this.descricao,
    required this.pais,
    this.estado,
    this.cidade,
    required this.latitude,
    required this.longitude,
    this.profundidadeMaxima,
    this.tipo,
    this.nivel,
    this.extended = const {},
  });

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'descricao': descricao,
        'pais': pais,
        'estado': estado,
        'cidade': cidade,
        'latitude': latitude,
        'longitude': longitude,
        'profundidadeMaxima': profundidadeMaxima,
        'tipo': tipo,
        'nivel': nivel,
        ...extended,
      };
}

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

  Future<DiveSiteModel> create(DiveSiteInput input) async {
    return DiveSiteModel.fromJson(await _api.post('/api/dive-sites', input.toJson()));
  }

  Future<DiveSiteModel> update(String id, DiveSiteInput input) async {
    return DiveSiteModel.fromJson(await _api.put('/api/dive-sites/$id', input.toJson()));
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
