import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme.dart';
import '../../../core/events.dart';
import '../../../core/maps/map_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/ui/widgets.dart';
import '../data/dive_site_model.dart';
import '../data/dive_sites_api.dart';
import 'dive_site_details_page.dart';

/// Explorar: mapa com busca de Dive Sites e seleção de país (foca o mapa nos locais do país).
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _api = DiveSitesApi();
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  List<DiveSiteModel> _sites = [];
  bool _loading = true;
  String? _error;

  String? _country;
  String _query = '';
  String? _selectedSiteId;
  MapLayerStyle _style = MapLayerStyle.streets;
  LatLng? _myPosition;

  @override
  void initState() {
    super.initState();
    _load();
    AppEvents.diveSitesChanged.addListener(_load);
  }

  @override
  void dispose() {
    AppEvents.diveSitesChanged.removeListener(_load);
    _mapController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!AppSession.instance.isLoggedIn) return;
    try {
      final sites = await _api.findAll();
      if (!mounted) return;
      setState(() {
        _sites = sites;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  // ------------------------------------------------------------ dados derivados

  String _countryOf(DiveSiteModel s) => s.pais.trim();

  /// (país, quantidade de locais), do mais populoso para o menos.
  List<(String, int)> get _countries {
    final counts = <String, int>{};
    for (final s in _sites) {
      final c = _countryOf(s);
      if (c.isEmpty) continue;
      counts[c] = (counts[c] ?? 0) + 1;
    }
    final list = counts.entries.map((e) => (e.key, e.value)).toList()
      ..sort((a, b) {
        final byCount = b.$2.compareTo(a.$2);
        return byCount != 0 ? byCount : a.$1.compareTo(b.$1);
      });
    return list;
  }

  List<DiveSiteModel> get _visibleSites {
    if (_country == null) return _sites;
    return _sites.where((s) => _countryOf(s) == _country).toList();
  }

  List<DiveSiteModel> get _searchResults {
    final q = _query.trim().toLowerCase();
    if (q.length < 2) return const [];
    return _sites
        .where((s) =>
            s.nome.toLowerCase().contains(q) ||
            s.localizacao.toLowerCase().contains(q))
        .take(6)
        .toList();
  }

  // ------------------------------------------------------------ ações

  void _fitToVisible() {
    final sites = _visibleSites;
    if (sites.isEmpty) return;

    if (_country == null) {
      _mapController.move(const LatLng(15, 0), 2);
      return;
    }
    if (sites.length == 1) {
      _mapController.move(LatLng(sites.first.latitude, sites.first.longitude), 10);
      return;
    }
    final points = sites.map((s) => LatLng(s.latitude, s.longitude)).toList();
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.fromLTRB(40, 190, 40, 170),
        maxZoom: 12,
      ),
    );
  }

  void _selectCountry(String? country) {
    setState(() {
      _country = country;
      _selectedSiteId = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitToVisible();
    });
  }

  void _focusSite(DiveSiteModel site, {bool openSheet = true}) {
    _searchFocus.unfocus();
    setState(() {
      _selectedSiteId = site.id;
      _query = '';
      _searchController.clear();
    });
    _mapController.move(LatLng(site.latitude, site.longitude), 11);
    if (openSheet) _showSite(site);
  }

  Future<void> _openSite(DiveSiteModel site) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DiveSiteDetailsPage(site: site)),
    );
    if (changed == true) AppEvents.notifyDiveSitesChanged();
  }

  Future<void> _locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) showSnack(context, 'Ative a localização do aparelho para usar esta função.', error: true);
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final p = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _myPosition = p);
      _mapController.move(p, 10);
    } catch (_) {
      if (mounted) showSnack(context, 'Não foi possível obter sua localização.', error: true);
    }
  }

  Future<void> _showCountrySheet() async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CountrySheet(countries: _countries, selected: _country),
    );
    // "" = limpar filtro; null = fechou sem escolher
    if (picked == null) return;
    _selectCountry(picked.isEmpty ? null : picked);
  }

  void _showSite(DiveSiteModel site) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: RemoteImage(
                      url: site.coverUrl,
                      cacheKey: site.images.isEmpty ? null : site.images.first.id,
                      width: 84,
                      height: 84,
                      placeholderIcon: Icons.location_on,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(site.nome, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 3),
                        Text(
                          site.localizacao.isEmpty ? '—' : site.localizacao,
                          style: const TextStyle(color: DiverrTheme.muted),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (site.tipo != null) InfoChip(text: tipoLabel(site.tipo)),
                            if (site.profundidadeMaxima != null)
                              InfoChip(icon: Icons.arrow_downward, text: '${site.profundidadeMaxima!.toStringAsFixed(0)} m', color: DiverrTheme.secondary),
                            if (site.ratingAverage != null)
                              InfoChip(icon: Icons.star_rounded, text: site.ratingAverage!.toStringAsFixed(1), color: DiverrTheme.gold),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openSite(site);
                },
                child: const Text('Ver local'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ UI

  Marker _marker(DiveSiteModel s) {
    final selected = s.id == _selectedSiteId;
    return Marker(
      point: LatLng(s.latitude, s.longitude),
      width: selected ? 50 : 42,
      height: selected ? 50 : 42,
      child: GestureDetector(
        onTap: () => _focusSite(s),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? DiverrTheme.primary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: DiverrTheme.primary, width: 2),
            boxShadow: DiverrTheme.softShadow,
          ),
          child: Icon(
            Icons.scuba_diving,
            size: selected ? 26 : 22,
            color: selected ? Colors.white : DiverrTheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    final results = _searchResults;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DiverrTheme.radiusSmall + 2),
            boxShadow: DiverrTheme.softShadow,
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Buscar Dive Sites, cidades ou países',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
        ),
        if (_query.trim().length >= 2)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(DiverrTheme.radiusSmall + 2),
              boxShadow: DiverrTheme.softShadow,
            ),
            child: results.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nenhum local encontrado.', style: TextStyle(color: DiverrTheme.muted)),
                  )
                : Column(
                    children: [
                      for (final s in results)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined, color: DiverrTheme.primary),
                          title: Text(s.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(s.localizacao.isEmpty ? '—' : s.localizacao, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => _focusSite(s),
                        ),
                    ],
                  ),
          ),
      ],
    );
  }

  Widget _countryChips() {
    final countries = _countries;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: const Icon(Icons.public, size: 18),
              label: const Text('Mundo'),
              selected: _country == null,
              onSelected: (_) => _selectCountry(null),
            ),
          ),
          for (final c in countries.take(8))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${c.$1} (${c.$2})'),
                selected: _country == c.$1,
                onSelected: (sel) => _selectCountry(sel ? c.$1 : null),
              ),
            ),
          if (countries.length > 8)
            ActionChip(
              avatar: const Icon(Icons.list, size: 18),
              label: const Text('Todos os países'),
              onPressed: _showCountrySheet,
            ),
        ],
      ),
    );
  }

  Widget _countryCarousel() {
    final sites = _visibleSites;
    return SizedBox(
      height: 132,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: sites.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final s = sites[i];
          return SizedBox(
            width: 270,
            child: ImageSideCard(
              imageUrl: s.coverUrl,
              cacheKey: s.images.isEmpty ? null : s.images.first.id,
              placeholderIcon: Icons.location_on,
              imageWidth: 90,
              minHeight: 112,
              showChevron: false,
              onTap: () => _focusSite(s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: s.id == _selectedSiteId ? DiverrTheme.primary : context.strongText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.cidade ?? s.pais,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: DiverrTheme.muted, fontSize: 12.5),
                  ),
                  if (s.ratingAverage != null) ...[
                    const SizedBox(height: 6),
                    InfoChip(icon: Icons.star_rounded, text: s.ratingAverage!.toStringAsFixed(1), color: DiverrTheme.gold),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleSites;

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(15, 0),
              initialZoom: 2,
              minZoom: 2,
              maxZoom: 18,
              onTap: (_, __) => _searchFocus.unfocus(),
            ),
            children: [
              MapConfig.tileLayer(_style),
              MarkerLayer(markers: visible.map(_marker).toList()),
              if (_myPosition != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _myPosition!,
                    width: 26,
                    height: 26,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: DiverrTheme.softShadow,
                      ),
                    ),
                  ),
                ]),
            ],
          ),
        ),

        // alternar entre mapa / satélite / híbrido (só com a chave do MapTiler)
        if (MapConfig.hasMaptiler)
          Positioned(
            right: 16,
            top: 150,
            child: FloatingActionButton.small(
              heroTag: 'layers',
              tooltip: 'Camada: ${MapConfig.label(_style)}',
              onPressed: () => setState(() => _style = MapConfig.next(_style)),
              backgroundColor: context.surfaceColor,
              foregroundColor: DiverrTheme.primary,
              child: const Icon(Icons.layers_outlined),
            ),
          ),

        // topo: busca + países
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _searchBar(),
                  const SizedBox(height: 10),
                  if (_query.trim().length < 2) _countryChips(),
                ],
              ),
            ),
          ),
        ),

        if (_loading)
          const Positioned.fill(
            child: IgnorePointer(child: Center(child: CircularProgressIndicator())),
          ),

        if (_error != null && _sites.isEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: ErrorState(message: _error!, onRetry: _load),
          ),

        if (!_loading && _error == null && _sites.isEmpty)
          const Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: EmptyState(
              icon: Icons.explore_outlined,
              title: 'Nenhum Dive Site ainda',
              message: 'Os pontos de mergulho cadastrados pela equipe aparecerão aqui.',
            ),
          ),

        // atribuição obrigatória do mapa
        Positioned(
          left: 8,
          bottom: _country != null && visible.isNotEmpty ? 158 : 6,
          child: MapConfig.attribution(),
        ),

        // base: botão localizar + carrossel do país
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 12),
                child: FloatingActionButton.small(
                  heroTag: 'locate',
                  onPressed: _locate,
                  backgroundColor: context.surfaceColor,
                  foregroundColor: DiverrTheme.primary,
                  child: const Icon(Icons.my_location),
                ),
              ),
              if (_country != null && visible.isNotEmpty) _countryCarousel(),
            ],
          ),
        ),
      ],
    );
  }
}

class _CountrySheet extends StatefulWidget {
  final List<(String, int)> countries;
  final String? selected;
  const _CountrySheet({required this.countries, required this.selected});

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final items = widget.countries.where((c) => q.isEmpty || c.$1.toLowerCase().contains(q)).toList();

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .75),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Escolher país', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _q = v),
                  decoration: const InputDecoration(hintText: 'Buscar país', prefixIcon: Icon(Icons.search)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.public, color: DiverrTheme.primary),
                title: const Text('Mundo (todos os países)', style: TextStyle(fontWeight: FontWeight.w700)),
                trailing: widget.selected == null ? const Icon(Icons.check, color: DiverrTheme.primary) : null,
                onTap: () => Navigator.pop(context, ''),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in items)
                      ListTile(
                        leading: const Icon(Icons.flag_outlined, color: DiverrTheme.muted),
                        title: Text(c.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${c.$2} ${c.$2 == 1 ? 'local' : 'locais'}'),
                        trailing: widget.selected == c.$1 ? const Icon(Icons.check, color: DiverrTheme.primary) : null,
                        onTap: () => Navigator.pop(context, c.$1),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
