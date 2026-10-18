import 'package:flutter/foundation.dart';

import 'local_store.dart';

/// Cache de Dive Sites para uso sem internet:
///  - automático: a última lista recebida do servidor (nomes, locais, coordenadas, dados básicos);
///  - por escolha do usuário ("Salvar offline"): detalhes completos do local, fixados no aparelho
///    (como baixar uma playlist do Spotify). As fotos são pré-carregadas no cache de imagens.
class SitesCache {
  SitesCache._();

  static const _allFile = 'sites_cache.json';
  static const _pinnedFile = 'pinned_sites.json';

  /// Ids dos locais salvos offline (a interface escuta para mostrar o selo "Offline").
  static final ValueNotifier<Set<String>> pinnedIds = ValueNotifier<Set<String>>(<String>{});

  static Map<String, dynamic> _pinned = {};
  static bool _loaded = false;

  static Future<void> init() async {
    if (_loaded) return;
    final raw = await LocalStore.readJson(_pinnedFile);
    if (raw is Map) _pinned = Map<String, dynamic>.from(raw);
    pinnedIds.value = _pinned.keys.toSet();
    _loaded = true;
  }

  static bool isPinned(String id) => pinnedIds.value.contains(id);

  /// Guarda a lista completa recebida (cache automático) e atualiza os locais fixados.
  static Future<void> saveAll(List<dynamic> raw) async {
    await init();
    await LocalStore.writeJson(_allFile, raw);

    var changed = false;
    for (final e in raw) {
      if (e is Map && _pinned.containsKey(e['id']?.toString())) {
        _pinned[e['id'].toString()] = Map<String, dynamic>.from(e);
        changed = true;
      }
    }
    if (changed) await LocalStore.writeJson(_pinnedFile, _pinned);
  }

  static Future<List<dynamic>?> loadAll() async {
    final raw = await LocalStore.readJson(_allFile);
    return raw is List ? raw : null;
  }

  static Future<void> pin(Map<String, dynamic> rawSite) async {
    await init();
    final id = rawSite['id']?.toString();
    if (id == null) return;
    _pinned[id] = rawSite;
    await LocalStore.writeJson(_pinnedFile, _pinned);
    pinnedIds.value = _pinned.keys.toSet();
  }

  static Future<void> unpin(String id) async {
    await init();
    _pinned.remove(id);
    await LocalStore.writeJson(_pinnedFile, _pinned);
    pinnedIds.value = _pinned.keys.toSet();
  }

  /// Procura um local nos fixados e, depois, no cache automático.
  static Future<Map<String, dynamic>?> findAny(String id) async {
    await init();
    final p = _pinned[id];
    if (p is Map) return Map<String, dynamic>.from(p);
    final all = await loadAll();
    if (all != null) {
      for (final e in all) {
        if (e is Map && e['id']?.toString() == id) return Map<String, dynamic>.from(e);
      }
    }
    return null;
  }

  /// Atualiza a cópia fixada com dados novos do servidor (se o local estiver fixado).
  static Future<void> refreshIfPinned(Map<String, dynamic> rawSite) async {
    await init();
    final id = rawSite['id']?.toString();
    if (id != null && _pinned.containsKey(id)) {
      _pinned[id] = rawSite;
      await LocalStore.writeJson(_pinnedFile, _pinned);
    }
  }
}
