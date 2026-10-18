import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'uuid.dart';

/// Armazenamento local simples em arquivos JSON na pasta do app (sobrevive a fechar o app/reiniciar).
/// Escrita atômica: grava em .tmp e renomeia, para não corromper o arquivo se o app fechar no meio.
class LocalStore {
  LocalStore._();

  static Directory? _root;

  static Future<Directory> root() async {
    if (_root != null) return _root!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/diverr');
    if (!await dir.exists()) await dir.create(recursive: true);
    return _root = dir;
  }

  static Future<File> _file(String name) async => File('${(await root()).path}/$name');

  static Future<dynamic> readJson(String name) async {
    try {
      final f = await _file(name);
      if (!await f.exists()) return null;
      final text = await f.readAsString();
      if (text.isEmpty) return null;
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  static Future<void> writeJson(String name, Object data) async {
    try {
      final f = await _file(name);
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(jsonEncode(data), flush: true);
      await tmp.rename(f.path);
    } catch (_) {
      // falha de disco não deve derrubar o app
    }
  }

  static Future<void> delete(String name) async {
    try {
      final f = await _file(name);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// Copia uma foto escolhida para uma pasta persistente (o cache do image_picker pode ser limpo pelo sistema)
  /// e devolve o novo caminho.
  static Future<String> savePendingPhoto(String sourcePath) async {
    final dir = Directory('${(await root()).path}/pending_photos');
    if (!await dir.exists()) await dir.create(recursive: true);
    final dot = sourcePath.lastIndexOf('.');
    final ext = (dot != -1 && sourcePath.length - dot <= 6) ? sourcePath.substring(dot) : '.jpg';
    final target = '${dir.path}/${newUuid()}$ext';
    await File(sourcePath).copy(target);
    return target;
  }

  static Future<void> deleteFile(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
