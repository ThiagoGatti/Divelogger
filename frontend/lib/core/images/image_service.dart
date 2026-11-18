import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../network/api_client.dart';

/// Escolhe foto (galeria/câmera), reduz o tamanho e envia DIRETO para o S3 via URL pré-assinada.
/// Fluxo: presign (backend valida dono e limite do plano) -> PUT no S3 -> registrar a key no backend.
class ImageService {
  final ApiClient _api;
  final ImagePicker _picker = ImagePicker();

  ImageService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<XFile?> pick(ImageSource source) {
    return _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 82,
    );
  }

  /// Foto de perfil: menor (800 px) para carregar rápido.
  Future<XFile?> pickAvatar(ImageSource source) {
    return _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
  }

  Future<List<XFile>> pickMany() {
    return _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 82,
    );
  }

  /// [basePath] ex.: /api/dive-logs/{id} ou /api/dive-sites/{id}.
  /// Retorna o JSON atualizado do recurso (com a nova imagem).
  Future<Map<String, dynamic>> upload(
    String basePath,
    XFile file, {
    String? presignPath,
    String? registerPath,
  }) async {
    final bytes = await file.readAsBytes();
    final contentType = _contentTypeOf(file);

    final presign = await _api.post(
      presignPath ?? '$basePath/images/presign',
      {'contentType': contentType, 'sizeBytes': bytes.length},
    );

    final uploadUrl = presign['uploadUrl'] as String?;
    final key = presign['key'] as String?;
    if (uploadUrl == null || key == null) {
      throw ApiException('Resposta inválida ao preparar o envio da foto.');
    }

    try {
      final res = await http
          .put(
            Uri.parse(uploadUrl),
            headers: {'Content-Type': contentType},
            body: bytes,
          )
          .timeout(const Duration(seconds: 90));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException('Falha ao enviar a foto (${res.statusCode}). Tente novamente.');
      }
    } on TimeoutException {
      throw ApiException('O envio da foto demorou demais. Verifique sua conexão.');
    } on http.ClientException {
      throw ApiException('Sem conexão para enviar a foto.');
    }

    return _api.post(registerPath ?? '$basePath/images', {'key': key});
  }

  String _contentTypeOf(XFile file) {
    final mime = file.mimeType?.toLowerCase();
    if (mime == 'image/png' || mime == 'image/webp' || mime == 'image/jpeg') {
      return mime!;
    }
    final name = file.path.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
