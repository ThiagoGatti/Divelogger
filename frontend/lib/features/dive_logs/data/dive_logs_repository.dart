import 'package:image_picker/image_picker.dart';

import '../../../core/images/image_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/offline/local_store.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/sync_service.dart';
import '../../../core/offline/uuid.dart';
import '../../../core/session/session.dart';
import 'dive_log_model.dart';
import 'dive_logs_api.dart';

/// Resultado de salvar um mergulho.
class SaveResult {
  final DiveLogModel log;

  /// true = parte do que foi feito ficou guardada no aparelho e será enviada quando houver internet.
  final bool queued;

  /// Fotos que o servidor recusou (ex.: limite do plano) e foram descartadas.
  final int photosFailed;

  const SaveResult({required this.log, this.queued = false, this.photosFailed = 0});
}

/// Único ponto de acesso aos mergulhos do usuário. Funciona online e offline:
///  - leitura: servidor -> cache local; sem rede, usa o cache; mergulhos pendentes são sobrepostos;
///  - escrita: tenta o servidor; sem rede, guarda na fila (inclusive fotos) e sincroniza depois.
class DiveLogsRepository {
  DiveLogsRepository._();
  static final DiveLogsRepository instance = DiveLogsRepository._();

  final _api = DiveLogsApi();
  final _images = ImageService();
  final _queue = OfflineQueue.instance;

  int get _uid => AppSession.instance.currentUser!.id;
  String get _cacheName => 'dives_$_uid.json';

  // ------------------------------------------------------------ leitura

  Future<List<DiveLogModel>> findMine() async {
    final ops = await _queue.opsFor(_uid);

    List<dynamic>? raw;
    try {
      raw = await _api.findMineRaw();
      await LocalStore.writeJson(_cacheName, raw);
    } on ApiException catch (e) {
      if (!e.isNetwork) rethrow;
      final cached = await LocalStore.readJson(_cacheName);
      if (cached is List) {
        raw = cached;
      } else if (ops.isEmpty) {
        rethrow; // sem cache e sem pendências: não há o que mostrar
      }
    }

    final base = (raw ?? const <dynamic>[])
        .map((e) => DiveLogModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return _overlay(base, ops);
  }

  Future<List<DiveLogModel>> findMineBySite(String siteId) async {
    final all = await findMine();
    return all.where((l) => l.diveSiteId == siteId).toList();
  }

  Future<DiveLogModel> findById(String id) async {
    final all = await findMine();
    for (final l in all) {
      if (l.id == id) return l;
    }
    throw ApiException('Mergulho não encontrado.', statusCode: 404);
  }

  List<DiveLogModel> _overlay(List<DiveLogModel> base, List<PendingOp> ops) {
    final result = [...base];
    for (final op in ops) {
      switch (op.type) {
        case 'create':
          result.add(_modelFromOp(op, id: op.localId!));
          break;
        case 'update':
          final i = result.indexWhere((l) => l.id == op.serverId);
          if (i >= 0) {
            result[i] = _modelFromOp(op, id: op.serverId!, imagens: result[i].imagens);
          }
          break;
        case 'photos':
          final i = result.indexWhere((l) => l.id == op.serverId);
          if (i >= 0) {
            final b = result[i];
            result[i] = DiveLogModel(
              id: b.id,
              diveSiteId: b.diveSiteId,
              diveSiteNome: b.diveSiteNome,
              dataHora: b.dataHora,
              duracaoMinutos: b.duracaoMinutos,
              profundidadeMaxima: b.profundidadeMaxima,
              profundidadeMedia: b.profundidadeMedia,
              visibilidade: b.visibilidade,
              temperaturaAgua: b.temperaturaAgua,
              corrente: b.corrente,
              tipoAgua: b.tipoAgua,
              tipoEntrada: b.tipoEntrada,
              tipoGas: b.tipoGas,
              pressaoInicial: b.pressaoInicial,
              pressaoFinal: b.pressaoFinal,
              notaExperiencia: b.notaExperiencia,
              notaLocal: b.notaLocal,
              comentarioLocal: b.comentarioLocal,
              ownerId: b.ownerId,
              ownerNome: b.ownerNome,
              ownerUsername: b.ownerUsername,
              observacoes: b.observacoes,
              imagens: b.imagens,
              pending: true,
              localPhotos: op.photos,
              syncError: op.error,
            );
          }
          break;
        case 'delete':
          result.removeWhere((l) => l.id == op.serverId);
          break;
      }
    }
    result.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return result;
  }

  DiveLogModel _modelFromOp(PendingOp op, {required String id, List<dynamic> imagens = const []}) {
    final me = AppSession.instance.currentUser!;
    return DiveLogModel.fromRequestBody(
      op.body,
      id: id,
      siteNome: op.siteNome ?? '',
      ownerId: me.id,
      ownerNome: me.nomeCompleto,
      ownerUsername: me.username,
      imagens: imagens.cast(),
      localPhotos: op.photos,
      syncError: op.error,
    );
  }

  // ------------------------------------------------------------ escrita

  Future<SaveResult> save({
    DiveLogModel? existing,
    required Map<String, dynamic> body,
    required String siteNome,
    List<XFile> newPhotos = const [],
    void Function(String message)? onProgress,
  }) async {
    // A) editar um mergulho que ainda NÃO chegou ao servidor: altera a própria criação pendente
    if (existing != null) {
      final createOp = await _queue.findCreate(_uid, existing.id);
      if (createOp != null) {
        createOp.body = {...body, 'clientId': createOp.localId};
        createOp.siteNome = siteNome;
        createOp.error = null;
        for (final f in newPhotos) {
          createOp.photos.add(await LocalStore.savePendingPhoto(f.path));
        }
        await _queue.save(_uid);
        SyncService.instance.scheduleSync();
        return SaveResult(log: _modelFromOp(createOp, id: createOp.localId!), queued: true);
      }
    }
    return existing == null
        ? _create(body, siteNome, newPhotos, onProgress)
        : _update(existing, body, siteNome, newPhotos, onProgress);
  }

  Future<SaveResult> _create(
    Map<String, dynamic> body,
    String siteNome,
    List<XFile> photos,
    void Function(String)? onProgress,
  ) async {
    final localId = newUuid();
    final payload = {...body, 'clientId': localId};

    try {
      onProgress?.call('Salvando mergulho…');
      final created = await _api.create(payload);
      final up = await _uploadPhotos(created.id, photos, onProgress);
      return SaveResult(log: created, queued: up.queued, photosFailed: up.failed);
    } on ApiException catch (e) {
      if (!e.isNetwork) rethrow;

      // sem conexão: guarda o mergulho (e as fotos) no aparelho
      final paths = <String>[];
      for (final f in photos) {
        paths.add(await LocalStore.savePendingPhoto(f.path));
      }
      final op = PendingOp(
        opId: newUuid(),
        type: 'create',
        localId: localId,
        body: payload,
        siteNome: siteNome,
        photos: paths,
      );
      await _queue.add(_uid, op);
      SyncService.instance.scheduleSync();
      return SaveResult(log: _modelFromOp(op, id: localId), queued: true);
    }
  }

  Future<SaveResult> _update(
    DiveLogModel existing,
    Map<String, dynamic> body,
    String siteNome,
    List<XFile> photos,
    void Function(String)? onProgress,
  ) async {
    // já existe uma edição pendente para este mergulho: junta tudo nela
    final pendingUpdate = await _queue.findByServer(_uid, 'update', existing.id);
    if (pendingUpdate != null) {
      pendingUpdate.body = body;
      pendingUpdate.siteNome = siteNome;
      pendingUpdate.error = null;
      for (final f in photos) {
        pendingUpdate.photos.add(await LocalStore.savePendingPhoto(f.path));
      }
      await _queue.save(_uid);
      SyncService.instance.scheduleSync();
      return SaveResult(log: _modelFromOp(pendingUpdate, id: existing.id, imagens: existing.imagens), queued: true);
    }

    try {
      onProgress?.call('Salvando mergulho…');
      final updated = await _api.update(existing.id, body);
      final up = await _uploadPhotos(updated.id, photos, onProgress);
      return SaveResult(log: updated, queued: up.queued, photosFailed: up.failed);
    } on ApiException catch (e) {
      if (!e.isNetwork) rethrow;

      final paths = <String>[];
      for (final f in photos) {
        paths.add(await LocalStore.savePendingPhoto(f.path));
      }
      final op = PendingOp(
        opId: newUuid(),
        type: 'update',
        serverId: existing.id,
        body: body,
        siteNome: siteNome,
        photos: paths,
      );
      await _queue.add(_uid, op);
      SyncService.instance.scheduleSync();
      return SaveResult(log: _modelFromOp(op, id: existing.id, imagens: existing.imagens), queued: true);
    }
  }

  /// Envia as fotos agora; se a rede cair no meio, guarda as restantes para depois.
  Future<({bool queued, int failed})> _uploadPhotos(
    String serverId,
    List<XFile> photos,
    void Function(String)? onProgress,
  ) async {
    var failed = 0;
    for (var i = 0; i < photos.length; i++) {
      onProgress?.call('Enviando foto ${i + 1} de ${photos.length}…');
      try {
        await _images.upload('/api/dive-logs/$serverId', photos[i]);
      } on ApiException catch (e) {
        if (e.isNetwork) {
          // guarda esta e as próximas para enviar depois
          final paths = <String>[];
          for (final f in photos.sublist(i)) {
            paths.add(await LocalStore.savePendingPhoto(f.path));
          }
          await _queue.add(
            _uid,
            PendingOp(opId: newUuid(), type: 'photos', serverId: serverId, photos: paths),
          );
          SyncService.instance.scheduleSync();
          return (queued: true, failed: failed);
        }
        failed++; // recusada pelo servidor (ex.: limite de fotos do plano)
      }
    }
    return (queued: false, failed: failed);
  }

  Future<void> delete(DiveLogModel log) async {
    // criado offline e ainda não enviado: basta descartar
    final createOp = await _queue.findCreate(_uid, log.id);
    if (createOp != null) {
      for (final p in createOp.photos) {
        await LocalStore.deleteFile(p);
      }
      await _queue.remove(_uid, createOp.opId);
      return;
    }

    try {
      await _api.delete(log.id);
      await _queue.removeAllForServer(_uid, log.id);
    } on ApiException catch (e) {
      if (!e.isNetwork) rethrow;
      await _queue.removeAllForServer(_uid, log.id); // descarta edições pendentes desse mergulho
      await _queue.add(_uid, PendingOp(opId: newUuid(), type: 'delete', serverId: log.id));
      SyncService.instance.scheduleSync();
    }
  }
}
