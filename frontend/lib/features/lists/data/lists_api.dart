import '../../../core/network/api_client.dart';
import 'list_models.dart';

class ListsApi {
  final ApiClient _api;
  ListsApi({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<ListSummary>> mine() async {
    final data = await _api.getList('/api/lists/me');
    return data
        .map((e) => ListSummary.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ListDetail> get(String id) async =>
      ListDetail.fromJson(await _api.get('/api/lists/$id'));

  Future<ListDetail> create(String nome, String? descricao, bool ranked) async =>
      ListDetail.fromJson(await _api.post(
        '/api/lists',
        {'nome': nome, 'descricao': descricao, 'ranked': ranked},
      ));

  Future<ListDetail> update(String id, String nome, String? descricao, bool ranked) async =>
      ListDetail.fromJson(await _api.put(
        '/api/lists/$id',
        {'nome': nome, 'descricao': descricao, 'ranked': ranked},
      ));

  Future<void> delete(String id) => _api.delete('/api/lists/$id');

  Future<ListDetail> addItem(String listId, String siteId, {String? nota}) async =>
      ListDetail.fromJson(await _api.post(
        '/api/lists/$listId/items',
        {'siteId': siteId, 'nota': nota},
      ));

  Future<ListDetail> removeItem(String listId, String itemId) async =>
      ListDetail.fromJson(await _api.deleteJson('/api/lists/$listId/items/$itemId'));

  Future<ListDetail> reorder(String listId, List<String> itemIds) async =>
      ListDetail.fromJson(await _api.put(
        '/api/lists/$listId/items/order',
        {'itemIds': itemIds},
      ));

  // ---- Quero mergulhar ----

  Future<ListDetail> wishlist() async =>
      ListDetail.fromJson(await _api.get('/api/lists/wishlist'));

  Future<ListDetail> addToWishlist(String siteId) async =>
      ListDetail.fromJson(await _api.post('/api/lists/wishlist/items', {'siteId': siteId}));

  Future<ListDetail> removeFromWishlist(String siteId) async =>
      ListDetail.fromJson(await _api.deleteJson('/api/lists/wishlist/items/site/$siteId'));
}
