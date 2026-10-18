import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/auth/data/me_api.dart';
import '../../features/dive_logs/data/dive_logs_api.dart';
import '../events.dart';
import '../images/image_service.dart';
import '../network/api_client.dart';
import '../session/session.dart';
import 'local_store.dart';
import 'offline_queue.dart';

class SyncState {
  final int pending; // aguardando envio
  final int errors; // recusados pelo servidor (o usuário decide)
  final bool syncing;
  final bool offline;
  final String? notice;

  const SyncState({
    this.pending = 0,
    this.errors = 0,
    this.syncing = false,
    this.offline = false,
    this.notice,
  });

  SyncState copyWith({int? pending, int? errors, bool? syncing, bool? offline, String? notice, bool clearNotice = false}) =>
      SyncState(
        pending: pending ?? this.pending,
        errors: errors ?? this.errors,
        syncing: syncing ?? this.syncing,
        offline: offline ?? this.offline,
        notice: clearNotice ? null : (notice ?? this.notice),
      );
}

/// Envia ao servidor, em ordem, o que foi feito sem internet. Roda ao abrir o app, ao voltar para o app
/// e quando a conexão retorna. Rede caiu no meio: para e tenta depois. Servidor recusou (ex.: local
/// desativado): marca erro e o usuário decide (tentar de novo ou descartar).
class SyncService with WidgetsBindingObserver {
  SyncService._();
  static final SyncService instance = SyncService._();

  final ValueNotifier<SyncState> state = ValueNotifier<SyncState>(const SyncState());

  final _logs = DiveLogsApi();
  final _images = ImageService();
  final _queue = OfflineQueue.instance;

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _running = false;
  bool _started = false;
  bool _connectivityOffline = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _queue.revision.addListener(_refreshCounts);

    Connectivity().checkConnectivity().then((r) {
      _connectivityOffline = !_isOnline(r);
      _emit();
      if (!_connectivityOffline) syncNow();
    });
    _sub = Connectivity().onConnectivityChanged.listen((r) {
      final wasOffline = _connectivityOffline;
      _connectivityOffline = !_isOnline(r);
      _emit();
      if (wasOffline && !_connectivityOffline) syncNow();
    });

    _refreshCounts();
  }

  bool _isOnline(List<ConnectivityResult> r) => r.any((e) => e != ConnectivityResult.none);

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) syncNow();
  }

  void _emit({bool? syncing, String? notice, bool clearNotice = false}) {
    state.value = state.value.copyWith(
      offline: _connectivityOffline,
      syncing: syncing,
      notice: notice,
      clearNotice: clearNotice,
    );
  }

  Future<void> _refreshCounts() async {
    final user = AppSession.instance.currentUser;
    if (user == null) {
      state.value = state.value.copyWith(pending: 0, errors: 0);
      return;
    }
    final ops = await _queue.opsFor(user.id);
    state.value = state.value.copyWith(
      pending: ops.where((o) => o.error == null).length,
      errors: ops.where((o) => o.error != null).length,
    );
  }

  void scheduleSync() {
    _refreshCounts();
    unawaited(syncNow());
  }

  void dismissNotice() => _emit(clearNotice: true);

  /// Recomeça uma operação que tinha dado erro.
  Future<void> retry(String opId) async {
    final user = AppSession.instance.currentUser;
    if (user == null) return;
    final ops = await _queue.opsFor(user.id);
    for (final o in ops) {
      if (o.opId == opId) o.error = null;
    }
    await _queue.save(user.id);
    unawaited(syncNow());
  }

  /// Descarta uma operação (e as fotos locais dela).
  Future<void> discard(String opId) async {
    final user = AppSession.instance.currentUser;
    if (user == null) return;
    final ops = await _queue.opsFor(user.id);
    for (final o in ops) {
      if (o.opId == opId) {
        for (final p in o.photos) {
          await LocalStore.deleteFile(p);
        }
      }
    }
    await _queue.remove(user.id, opId);
    AppEvents.notifyDiveLogsChanged();
  }

  Future<void> syncNow() async {
    if (_running || _connectivityOffline) return;
    final user = AppSession.instance.currentUser;
    if (user == null || !AppSession.instance.isLoggedIn) return;

    _running = true;
    var anyDone = false;
    final notices = <String>[];
    try {
      var ops = await _queue.opsFor(user.id);
      if (ops.where((o) => o.error == null).isEmpty) return;

      _emit(syncing: true);

      for (final op in ops) {
        if (op.error != null) continue; // aguardando decisão do usuário
        try {
          await _run(user.id, op, notices);
          await _queue.remove(user.id, op.opId);
          anyDone = true;
        } on ApiException catch (e) {
          if (e.isNetwork) {
            break; // sem rede: tenta de novo depois, mantendo a ordem
          }
          if (e.isUnauthorized) {
            break; // sessão expirou: o ApiClient já pediu novo login; a fila continua guardada
          }
          op.error = e.message;
          await _queue.save(user.id);
        }
      }
    } finally {
      _running = false;
      _emit(syncing: false, notice: notices.isEmpty ? null : notices.join('\n'));
      await _refreshCounts();
      if (anyDone) {
        AppEvents.notifyDiveLogsChanged();
        unawaited(MeApi().refresh());
      }
    }
  }

  Future<void> _run(int userId, PendingOp op, List<String> notices) async {
    switch (op.type) {
      case 'create':
        final created = await _logs.create(op.body); // body já leva clientId: reenvio não duplica
        await _uploadPhotos(userId, op, created.id, notices);
        break;
      case 'update':
        await _logs.update(op.serverId!, op.body);
        await _uploadPhotos(userId, op, op.serverId!, notices);
        break;
      case 'photos':
        await _uploadPhotos(userId, op, op.serverId!, notices);
        break;
      case 'delete':
        try {
          await _logs.delete(op.serverId!);
        } on ApiException catch (e) {
          if (e.statusCode != 404) rethrow; // já não existe: objetivo cumprido
        }
        break;
    }
  }

  /// Envia as fotos uma a uma; cada foto enviada sai da fila. Foto recusada pelo servidor é descartada
  /// com aviso ("insira de novo se quiser"); falha de rede interrompe e mantém o restante.
  Future<void> _uploadPhotos(int userId, PendingOp op, String serverId, List<String> notices) async {
    for (final path in List<String>.of(op.photos)) {
      try {
        await _images.upload('/api/dive-logs/$serverId', XFile(path));
      } on ApiException catch (e) {
        if (e.isNetwork || e.isUnauthorized) rethrow;
        notices.add('Uma foto não foi enviada: ${e.message} Você pode adicioná-la de novo no mergulho.');
      }
      op.photos.remove(path);
      await LocalStore.deleteFile(path);
      await _queue.save(userId);
    }
  }
}
