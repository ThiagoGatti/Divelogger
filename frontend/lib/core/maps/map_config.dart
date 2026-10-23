import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

enum MapLayerStyle { streets, satellite, hybrid }

/// Fonte das imagens do mapa. Usa o MapTiler (com satélite) quando há chave; sem chave, cai no
/// OpenStreetMap só para desenvolvimento (sem satélite).
///
/// A chave entra na hora de gerar o app:  --dart-define=MAPTILER_KEY=...  (ou nos arquivos env/*.json).
class MapConfig {
  MapConfig._();

  static const String maptilerKey = String.fromEnvironment('MAPTILER_KEY');

  static bool get hasMaptiler => maptilerKey.isNotEmpty && !maptilerKey.startsWith('COLE_');

  static const double maxZoom = 19;

  static String _path(MapLayerStyle s) {
    switch (s) {
      case MapLayerStyle.streets:
        return 'streets-v2';
      case MapLayerStyle.satellite:
        return 'satellite';
      case MapLayerStyle.hybrid:
        return 'hybrid';
    }
  }

  static String _ext(MapLayerStyle s) => s == MapLayerStyle.satellite ? 'jpg' : 'png';

  static String label(MapLayerStyle s) {
    switch (s) {
      case MapLayerStyle.streets:
        return 'Mapa';
      case MapLayerStyle.satellite:
        return 'Satélite';
      case MapLayerStyle.hybrid:
        return 'Híbrido';
    }
  }

  static MapLayerStyle next(MapLayerStyle s) {
    switch (s) {
      case MapLayerStyle.streets:
        return MapLayerStyle.satellite;
      case MapLayerStyle.satellite:
        return MapLayerStyle.hybrid;
      case MapLayerStyle.hybrid:
        return MapLayerStyle.streets;
    }
  }

  static TileLayer tileLayer(MapLayerStyle style) {
    if (!hasMaptiler) {
      return TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'log.dive.diver',
        maxZoom: maxZoom,
      );
    }
    // Tiles de 512 px (menos requisições que 256 px para o mesmo detalhe).
    return TileLayer(
      urlTemplate: 'https://api.maptiler.com/maps/${_path(style)}/{z}/{x}/{y}.${_ext(style)}?key=$maptilerKey',
      userAgentPackageName: 'log.dive.diver',
      tileDimension: 512,
      zoomOffset: -1,
      maxZoom: maxZoom,
    );
  }

  /// Atribuição exigida pelo MapTiler e pelo OpenStreetMap: deve ficar visível sobre o mapa.
  static Widget attribution() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.75),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        hasMaptiler ? '© MapTiler © OpenStreetMap contributors' : '© OpenStreetMap contributors',
        style: const TextStyle(fontSize: 10, color: Colors.black87),
      ),
    );
  }
}
