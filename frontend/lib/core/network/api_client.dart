import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../session/session.dart';
import 'api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  /// Código estável enviado pelo backend (ex.: PLAN_LIMIT).
  final String? code;

  ApiException(this.message, {this.statusCode, this.code});

  bool get isPlanLimit => code == 'PLAN_LIMIT';

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNetwork => statusCode == null;

  @override
  String toString() => message;
}

/// Cliente HTTP único do app: base URL, JSON, token Bearer, timeout e erros padronizados.
class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Uri _uri(String path) {
    try {
      return Uri.parse('${ApiConfig.baseUrl}$path');
    } on StateError catch (e) {
      // Build sem URL do servidor / release com HTTP: mostra a causa real em vez de "sem conexão".
      throw ApiException(e.message);
    }
  }

  Map<String, String> _headers({required bool auth}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = AppSession.instance.accessToken;
    if (auth && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ---- Métodos públicos -------------------------------------------------

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final json = await _send(
      auth,
      () => _client.post(_uri(path), headers: _headers(auth: auth), body: jsonEncode(body)),
    );
    return _asMap(json);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final json = await _send(
      true,
      () => _client.put(_uri(path), headers: _headers(auth: true), body: jsonEncode(body)),
    );
    return _asMap(json);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final json = await _send(
      true,
      () => _client.patch(_uri(path), headers: _headers(auth: true), body: jsonEncode(body)),
    );
    return _asMap(json);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final json = await _send(true, () => _client.get(_uri(path), headers: _headers(auth: true)));
    return _asMap(json);
  }

  Future<List<dynamic>> getList(String path) async {
    final json = await _send(true, () => _client.get(_uri(path), headers: _headers(auth: true)));
    if (json is List) return json;
    throw ApiException('Resposta inesperada do servidor.');
  }

  Future<void> delete(String path) async {
    await _send(true, () => _client.delete(_uri(path), headers: _headers(auth: true)));
  }

  /// DELETE que devolve o recurso atualizado (ex.: remover foto).
  Future<Map<String, dynamic>> deleteJson(String path) async {
    final json = await _send(true, () => _client.delete(_uri(path), headers: _headers(auth: true)));
    return _asMap(json);
  }

  // ---- Internos ---------------------------------------------------------

  Future<dynamic> _send(bool auth, Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(ApiConfig.requestTimeout);
    } on TimeoutException {
      throw ApiException('O servidor demorou para responder. Tente novamente.');
    } on http.ClientException {
      throw ApiException('Sem conexão com o servidor (${ApiConfig.host}). Verifique sua internet.');
    }

    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        decoded = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    // Token expirado/inválido em chamada autenticada => derruba a sessão.
    if (response.statusCode == 401 && auth && AppSession.instance.isLoggedIn) {
      await AppSession.instance.expire();
      throw ApiException('Sua sessão expirou. Entre novamente.', statusCode: 401);
    }

    throw ApiException(
      _messageFor(response.statusCode, decoded),
      statusCode: response.statusCode,
      code: decoded is Map ? decoded['code']?.toString() : null,
    );
  }

  String _messageFor(int status, dynamic decoded) {
    if (decoded is Map && decoded['message'] != null) {
      return decoded['message'].toString();
    }
    switch (status) {
      case 401:
        return 'Não autorizado.';
      case 403:
        return 'Você não tem permissão para esta ação.';
      case 404:
        return 'Não encontrado.';
      case 409:
        return 'Este registro já existe.';
      default:
        return status >= 500
            ? 'Erro no servidor. Tente novamente em instantes.'
            : 'Erro na comunicação com o servidor.';
    }
  }

  Map<String, dynamic> _asMap(dynamic json) {
    if (json == null) return <String, dynamic>{};
    if (json is Map) return Map<String, dynamic>.from(json);
    throw ApiException('Resposta inesperada do servidor.');
  }
}
