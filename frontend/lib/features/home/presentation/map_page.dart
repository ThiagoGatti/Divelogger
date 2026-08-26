import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, mergulhador 👋',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Explore o oceano',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: DiverrTheme.dark,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_none,
                  ),
                ),
              ],
            ),
          ),

          // MAPA
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
              ),
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(0, 0),
                  initialZoom: 2,
                  minZoom: 2,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.log.diverr.diver',
                    maxZoom: 19,
                  ),

                  // MARCADORES DE EXEMPLO
                  MarkerLayer(



                    markers: [
                      _buildMarker(
                        latitude: -23.5505,
                        longitude: -46.6333,
                      ),

                      _buildMarker(
                        latitude: -22.9068,
                        longitude: -43.1729,
                      ),

                      _buildMarker(
                        latitude: -8.0476,
                        longitude: -34.8770,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ESTATÍSTICAS
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                _stat('12', 'Mergulhos'),
                _stat('5', 'Sites'),
                _stat('18.4 m', 'Maior profundidade'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Marker _buildMarker({
    required double latitude,
    required double longitude,
  }) {
    return Marker(
      point: LatLng(latitude, longitude),
      width: 45,
      height: 45,
      child: Container(
        decoration: BoxDecoration(
          color: DiverrTheme.primary,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 6,
              color: Colors.black26,
            ),
          ],
        ),
        child: const Icon(
          Icons.location_on,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  static Widget _stat(
      String value,
      String label,
      ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}