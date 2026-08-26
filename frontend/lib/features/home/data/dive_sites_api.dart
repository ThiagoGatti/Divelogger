import '../../../core/network/api_client.dart';
import 'dive_site_model.dart';

class DiveSitesApi {
  final ApiClient _api;

  DiveSitesApi({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<DiveSiteModel>> findAll() async {
    print('========================================');
    print('DIVE SITES API - buscando sites...');
    print('Endpoint: /api/dive-sites');

    final data = await _api.getList('/api/dive-sites');

    print('DIVE SITES API - resposta recebida');
    print('Quantidade: ${data.length}');
    print('Dados: $data');
    print('========================================');

    final sites = data
        .map(
          (e) {
        print('Convertendo Dive Site: $e');

        return DiveSiteModel.fromJson(
          Map<String, dynamic>.from(e),
        );
      },
    )
        .toList();

    print('Sites convertidos: ${sites.length}');

    for (final site in sites) {
      print(
        'SITE: ${site.nome} '
            '| lat: ${site.latitude} '
            '| long: ${site.longitude}',
      );
    }

    return sites;
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
    required int createdBy,
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
        'createdBy': createdBy,
      },
    );

    return DiveSiteModel.fromJson(json);
  }
}