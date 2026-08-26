import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final response = await _client.post(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<List<dynamic>> getList(String path) async {
    final response = await _client.get(_uri(path));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Erro ${response.statusCode}: ${response.body}', statusCode: response.statusCode);
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? {} : jsonDecode(response.body);
    } catch (_) {
      decoded = {};
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Erro na comunicação com o servidor.';
      throw ApiException(message, statusCode: response.statusCode);
    }

    return Map<String, dynamic>.from(decoded as Map);
  }
}
