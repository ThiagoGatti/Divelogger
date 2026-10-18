import 'package:image_picker/image_picker.dart';

import '../../../core/images/image_service.dart';
import '../../../core/network/api_client.dart';
import 'operator_models.dart';

class OperatorsApi {
  final ApiClient _api;
  OperatorsApi({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<OperatorSummary>> list({bool includeInactive = false}) async {
    final data = await _api.getList(
      includeInactive ? '/api/operators?includeInactive=true' : '/api/operators',
    );
    return data
        .map((e) => OperatorSummary.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<OperatorDetail> get(String id) async =>
      OperatorDetail.fromJson(await _api.get('/api/operators/$id'));

  Future<OperatorDetail> create(String nome, String? endereco) async =>
      OperatorDetail.fromJson(await _api.post('/api/operators', {'nome': nome, 'endereco': endereco}));

  Future<OperatorDetail> update(String id, String nome, String? endereco) async =>
      OperatorDetail.fromJson(await _api.put('/api/operators/$id', {'nome': nome, 'endereco': endereco}));

  Future<OperatorDetail> setAtivo(String id, bool ativo) async =>
      OperatorDetail.fromJson(await _api.patch('/api/operators/$id/ativo', {'ativo': ativo}));

  /// Define em quais Dive Sites a operadora atua (substitui os vínculos atuais).
  Future<OperatorDetail> setSites(String id, List<String> siteIds) async =>
      OperatorDetail.fromJson(await _api.put('/api/operators/$id/sites', {'siteIds': siteIds}));

  Future<OperatorDetail> uploadPhoto(String id, XFile file) async {
    final json = await ImageService(api: _api).upload(
      '',
      file,
      presignPath: '/api/operators/$id/photo/presign',
      registerPath: '/api/operators/$id/photo',
    );
    return OperatorDetail.fromJson(json);
  }

  Future<OperatorDetail> removePhoto(String id) async =>
      OperatorDetail.fromJson(await _api.deleteJson('/api/operators/$id/photo'));
}
