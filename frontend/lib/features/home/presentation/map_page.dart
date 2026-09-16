import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dive_site_details_page.dart';
import '../../../app/theme.dart';
import '../../../core/session/session.dart';
import '../data/dive_site_model.dart';
import '../data/dive_sites_api.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final DiveSitesApi _api = DiveSitesApi();

  List<DiveSiteModel> _sites = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sites = await _api.findAll();

      if (!mounted) return;

      setState(() {
        _sites = sites;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AppSession.instance.currentUser;

    final firstName = user?.nomeCompleto
        .split(' ')
        .first ??
        'mergulhador';

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, $firstName 👋',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 3),

                      const Text(
                        'Explore o oceano',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: DiverrTheme.dark,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: _loadSites,
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: const MapOptions(
                      initialCenter: LatLng(0, 0),
                      initialZoom: 2,
                      minZoom: 2,
                      maxZoom: 18,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                        'com.log.diverr.diver',
                        maxZoom: 19,
                      ),

                      MarkerLayer(
                        markers: _sites
                            .map(_buildMarker)
                            .toList(),
                      ),
                    ],
                  ),

                  Positioned(
                    top: 14,
                    left: 14,
                    child: _buildMapBadge(),
                  ),

                  if (_loading)
                    const Positioned(
                      top: 14,
                      right: 14,
                      child: _MapPill(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),

                  if (_error != null && _sites.isEmpty)
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.cloud_off,
                                color: Colors.orange,
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: Text(
                                  'Não foi possível carregar os '
                                      'Dive Sites. O mapa continua disponível.',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: FloatingActionButton.small(
                      onPressed: () {
                        _mapController.move(
                          const LatLng(0, 0),
                          2,
                        );
                      },
                      backgroundColor: Colors.white,
                      foregroundColor: DiverrTheme.primary,
                      child: const Icon(
                        Icons.public,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              12,
            ),
            child: Row(
              children: [
                _stat(
                  '${_sites.length}',
                  'Sites',
                ),

                _stat(
                  '—',
                  'Mergulhos',
                ),

                _stat(
                  '—',
                  'Maior profundidade',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildMarker(DiveSiteModel site) {
    return Marker(
      point: LatLng(
        site.latitude,
        site.longitude,
      ),
      width: 48,
      height: 58,
      child: GestureDetector(
        onTap: () => _showSite(site),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
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
                size: 21,
              ),
            ),

            const SizedBox(height: 2),

            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: DiverrTheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBadge() {
    return _MapPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on,
            size: 18,
            color: DiverrTheme.primary,
          ),

          const SizedBox(width: 6),

          Text(
            '${_sites.length} Dive Sites',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: DiverrTheme.dark,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showSite(DiveSiteModel site) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final location = [
          site.cidade,
          site.estado,
          site.pais,
        ]
            .where(
              (value) =>
          value != null &&
              value!.isNotEmpty,
        )
            .join(', ');

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            4,
            20,
            28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                site.nome,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 5),

              if (location.isNotEmpty)
                Text(
                  location,
                  style: TextStyle(
                    color: Colors.red.shade600,
                  ),
                ),




              if (site.profundidadeMaxima != null) ...[
                const SizedBox(height: 14),

                Text(
                  'Profundidade máxima: '
                      '${site.profundidadeMaxima} m',
                ),
              ],

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DiveSiteDetailsPage(
                          site: site,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Ver Local',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapPill extends StatelessWidget {
  final Widget child;

  const _MapPill({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        child: child,
      ),
    );
  }
}