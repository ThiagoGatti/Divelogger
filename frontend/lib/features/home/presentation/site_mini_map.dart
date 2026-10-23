import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme.dart';
import '../../../core/maps/map_config.dart';

/// Pré-visualização fixa do local no mapa (satélite + nomes), para conferir a posição na página do Dive Site.
class SiteMiniMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double height;
  const SiteMiniMap({super.key, required this.latitude, required this.longitude, this.height = 190});

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(DiverrTheme.radius),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 14,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                MapConfig.tileLayer(MapConfig.hasMaptiler ? MapLayerStyle.hybrid : MapLayerStyle.streets),
                MarkerLayer(markers: [
                  Marker(
                    point: point,
                    width: 30,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: DiverrTheme.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: DiverrTheme.softShadow,
                      ),
                    ),
                  ),
                ]),
              ],
            ),
            Positioned(left: 6, bottom: 6, child: MapConfig.attribution()),
          ],
        ),
      ),
    );
  }
}
