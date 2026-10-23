import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme.dart';
import '../../../core/maps/coordinate_parser.dart';
import '../../../core/maps/map_config.dart';
import '../../../core/ui/widgets.dart';

/// Escolha do ponto exato de um Dive Site: o mapa se move por baixo de uma CRUZ fixa no centro, e as
/// coordenadas mostradas são as do ponto sob a cruz (6 casas decimais, ~10 cm). Com satélite dá para
/// conferir visualmente que o ponto está sobre o recife/naufrágio. Devolve um [LatLng].
class LocationPickerPage extends StatefulWidget {
  final ({double lat, double lng})? initial;
  const LocationPickerPage({super.key, this.initial});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final _controller = MapController();
  final _paste = TextEditingController();

  late final ValueNotifier<LatLng> _center = ValueNotifier<LatLng>(
    widget.initial != null
        ? LatLng(widget.initial!.lat, widget.initial!.lng)
        : const LatLng(-14.2, -51.9), // Brasil
  );

  MapLayerStyle _style = MapConfig.hasMaptiler ? MapLayerStyle.hybrid : MapLayerStyle.streets;

  LatLng? _myPosition;
  double? _accuracy;
  bool _locating = false;

  @override
  void dispose() {
    _controller.dispose();
    _paste.dispose();
    _center.dispose();
    super.dispose();
  }

  void _goTo(LatLng p, {double? zoom}) {
    _center.value = p;
    final current = _controller.camera.zoom;
    _controller.move(p, zoom ?? (current < 15 ? 16 : current));
  }

  void _applyPasted() {
    final text = _paste.text.trim();
    if (text.isEmpty) return;

    final pair = CoordinateParser.parsePair(text);
    if (pair == null) {
      showSnack(
        context,
        'Não entendi essas coordenadas. Exemplos: -25.4991, -48.3202  ou  25°29\'56"S 48°19\'12"W',
        error: true,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    _paste.clear();
    _goTo(LatLng(pair.lat, pair.lng), zoom: 17);
  }

  /// Leitura NOVA do GPS (nunca usa posição antiga) e mostra a precisão.
  Future<void> _useMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) showSnack(context, 'Ative a localização do aparelho.', error: true);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) showSnack(context, 'Permissão de localização negada.', error: true);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 30),
        ),
      );
      if (!mounted) return;

      final p = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _myPosition = p;
        _accuracy = pos.accuracy;
      });
      _goTo(p, zoom: 17);

      if (pos.accuracy > 50) {
        showSnack(
          context,
          'Precisão baixa (±${pos.accuracy.round()} m). Confira no mapa e ajuste o ponto.',
        );
      }
    } on TimeoutException {
      if (mounted) {
        showSnack(context, 'Não foi possível obter um sinal de GPS preciso. Tente em local aberto.', error: true);
      }
    } catch (_) {
      if (mounted) showSnack(context, 'Não foi possível obter sua localização.', error: true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Widget _crosshair() {
    return IgnorePointer(
      child: Center(
        child: SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 56, height: 2, color: Colors.white),
              Container(width: 2, height: 56, color: Colors.white),
              Container(width: 56, height: 1, color: Colors.black54),
              Container(width: 1, height: 56, color: Colors.black54),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  color: DiverrTheme.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasInitial = widget.initial != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Marcar o ponto no mapa')),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: _center.value,
                initialZoom: hasInitial ? 16 : 4,
                minZoom: 2,
                maxZoom: MapConfig.maxZoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onPositionChanged: (camera, _) => _center.value = camera.center,
              ),
              children: [
                MapConfig.tileLayer(_style),
                if (_myPosition != null && _accuracy != null)
                  CircleLayer(circles: [
                    CircleMarker(
                      point: _myPosition!,
                      radius: _accuracy!,
                      useRadiusInMeter: true,
                      color: Colors.blue.withOpacity(.15),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 1.5,
                    ),
                  ]),
              ],
            ),
          ),
          _crosshair(),

          // topo: coordenadas do ponto sob a cruz + campo para colar coordenadas
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder<LatLng>(
                      valueListenable: _center,
                      builder: (_, c, __) => Row(
                        children: [
                          const Icon(Icons.my_location, size: 18, color: DiverrTheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${c.latitude.toStringAsFixed(6)},  ${c.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _paste,
                        textInputAction: TextInputAction.go,
                        onSubmitted: (_) => _applyPasted(),
                        style: const TextStyle(fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'Colar coordenadas (ex.: -25.4991, -48.3202)',
                          hintStyle: const TextStyle(fontSize: 12.5),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: _applyPasted,
                            tooltip: 'Ir para estas coordenadas',
                          ),
                        ),
                      ),
                    ),
                    if (!MapConfig.hasMaptiler) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Sem chave do MapTiler neste build: usando o mapa padrão, sem satélite.',
                        style: TextStyle(fontSize: 11.5, color: DiverrTheme.warning),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // atribuição obrigatória
          Positioned(left: 8, bottom: 150, child: MapConfig.attribution()),

          // base: camadas, GPS e confirmar
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (MapConfig.hasMaptiler)
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<MapLayerStyle>(
                            showSelectedIcon: false,
                            segments: [
                              for (final s in const [MapLayerStyle.satellite, MapLayerStyle.hybrid, MapLayerStyle.streets])
                                ButtonSegment(value: s, label: Text(MapConfig.label(s))),
                            ],
                            selected: {_style},
                            onSelectionChanged: (v) => setState(() => _style = v.first),
                          ),
                        ),
                      if (MapConfig.hasMaptiler) const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _locating ? null : _useMyLocation,
                              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                              icon: _locating
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.gps_fixed),
                              label: Text(
                                _locating
                                    ? 'Obtendo GPS…'
                                    : (_accuracy == null ? 'Minha localização' : 'GPS ±${_accuracy!.round()} m'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => Navigator.pop(context, _center.value),
                              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                              icon: const Icon(Icons.check),
                              label: const Text('Usar este ponto'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
