import 'package:flutter/foundation.dart';

import 'local_store.dart';

/// Operação feita sem conexão, aguardando envio ao servidor.
///  create : mergulho novo (localId = clientId enviado ao servidor)
///  update : edição de mergulho que já existe no servidor (serverId)
///  photos : só fotos para um mergulho já existente (serverId)
///  delete : exclusão de mergulho existente (serverId)
class PendingOp {
  final String opId;
  final String type;
  final String? localId;
  final String? serverId;
  Map<String, dynamic> body;
  String? siteNome;
  List<String> photos;
  String? error;
  final DateTime createdAt;

  PendingOp({
    required this.opId,
    required this.type,
    this.localId,
    this.serverId,
    Map<String, dynamic>? body,
    this.siteNome,
    List<String>? photos,
    this.error,
    DateTime? createdAt,
  })  : body = body ?? {},
        photos = photos ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'opId': opId,
        'type': type,
        'localId': localId,
        'serverId': serverId,
        'body': body,
        'siteNome': siteNome,
        'photos': photos,
        'error': error,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingOp.fromJson(Map<String, dynamic> j) => PendingOp(
        opId: j['opId']?.toString() ?? '',
        type: j['type']?.toString() ?? 'create',
        localId: j['localId'] as String?,
        serverId: j['serverId'] as String?,
        body: j['body'] is Map ? Map<String, dynamic>.from(j['body'] as Map) : {},
        siteNome: j['siteNome'] as String?,
        photos: (j['photos'] as List? ?? []).map((e) => e.toString()).toList(),
        error: j['error'] as String?,
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

/// Fila persistente de operações pendentes, uma por usuário (arquivo queue_<id>.json).
/// A fila NÃO é apagada ao sair da conta: se a sessão expirar offline, nada se perde.
class OfflineQueue {
  OfflineQueue._();
  static final OfflineQueue instance = OfflineQueue._();

  /// Incrementa a cada alteração (a interface escuta para atualizar contadores).
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  int? _userId;
  List<PendingOp> _ops = [];

  Future<void> _ensure(int userId) async {
    if (_userId == userId) return;
    _userId = userId;
    final raw = await LocalStore.readJson('queue_$userId.json');
    _ops = raw is List
        ? raw.whereType<Map>().map((e) => PendingOp.fromJson(Map<String, dynamic>.from(e))).toList()
        : [];
  }

  Future<List<PendingOp>> opsFor(int userId) async {
    await _ensure(userId);
    return List<PendingOp>.of(_ops);
  }

  Future<void> add(int userId, PendingOp op) async {
    await _ensure(userId);
    _ops.add(op);
    await save(userId);
  }

  Future<void> remove(int userId, String opId) async {
    await _ensure(userId);
    _ops.removeWhere((o) => o.opId == opId);
    await save(userId);
  }

  /// Persiste alterações feitas diretamente em objetos [PendingOp].
  Future<void> save(int userId) async {
    await _ensure(userId);
    await LocalStore.writeJson('queue_$userId.json', _ops.map((o) => o.toJson()).toList());
    revision.value++;
  }

  Future<PendingOp?> findCreate(int userId, String localId) async {
    await _ensure(userId);
    for (final o in _ops) {
      if (o.type == 'create' && o.localId == localId) return o;
    }
    return null;
  }

  Future<PendingOp?> findByServer(int userId, String type, String serverId) async {
    await _ensure(userId);
    for (final o in _ops) {
      if (o.type == type && o.serverId == serverId) return o;
    }
    return null;
  }

  /// Remove operações pendentes de um mergulho do servidor (ex.: ele foi excluído) e apaga as fotos locais.
  Future<void> removeAllForServer(int userId, String serverId) async {
    await _ensure(userId);
    final toRemove = _ops.where((o) => o.serverId == serverId && o.type != 'delete').toList();
    for (final o in toRemove) {
      for (final p in o.photos) {
        await LocalStore.deleteFile(p);
      }
    }
    _ops.removeWhere((o) => toRemove.contains(o));
    await save(userId);
  }
}
