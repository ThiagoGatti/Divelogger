import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/events.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/ui/widgets.dart';
import '../data/dive_site_model.dart';
import '../data/dive_sites_api.dart';
import 'create_dive_site_page.dart';
import 'dive_site_details_page.dart';

class DiveSitesPage extends StatefulWidget {
  const DiveSitesPage({super.key});

  @override
  State<DiveSitesPage> createState() => _DiveSitesPageState();
}

class _DiveSitesPageState extends State<DiveSitesPage> {
  final _api = DiveSitesApi();

  List<DiveSiteModel> _sites = [];
  String _query = '';
  String? _tipo;
  bool _showInactive = false;
  bool _loading = true;
  String? _error;

  bool get _isAdmin => AppSession.instance.isAdmin;

  @override
  void initState() {
    super.initState();
    _load();
    AppEvents.diveSitesChanged.addListener(_load);
  }

  @override
  void dispose() {
    AppEvents.diveSitesChanged.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!AppSession.instance.isLoggedIn) return;
    try {
      final sites = await _api.findAll(includeInactive: _isAdmin && _showInactive);
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

  List<DiveSiteModel> get _filtered {
    final q = _query.trim().toLowerCase();
    return _sites.where((s) {
      if (_tipo != null && s.tipo != _tipo) return false;
      if (q.isEmpty) return true;
      return s.nome.toLowerCase().contains(q) || s.localizacao.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _create() async {
    final site = await Navigator.of(context).push<DiveSiteModel>(
      MaterialPageRoute(builder: (_) => const CreateDiveSitePage()),
    );
    if (site == null || !mounted) return;
    AppEvents.notifyDiveSitesChanged();
    // Abre o local recém-criado para já adicionar as fotos.
    await _open(site);
  }

  Future<void> _open(DiveSiteModel site) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DiveSiteDetailsPage(site: site)),
    );
    if (changed == true) {
      AppEvents.notifyDiveSitesChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final tiposPresentes = _sites.map((s) => s.tipo).whereType<String>().toSet().toList()..sort();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
          children: [
            PageHeader(
              title: 'Dive Sites',
              subtitle: _isAdmin
                  ? 'Gerencie os pontos de mergulho disponíveis no app.'
                  : 'Explore os pontos de mergulho e registre seus mergulhos neles.',
              trailing: _isAdmin
                  ? IconButton.filled(
                      onPressed: _create,
                      icon: const Icon(Icons.add),
                      tooltip: 'Novo Dive Site',
                    )
                  : null,
            ),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou cidade',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            if (tiposPresentes.length > 1) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('Todos'),
                        selected: _tipo == null,
                        onSelected: (_) => setState(() => _tipo = null),
                      ),
                    ),
                    for (final t in tiposPresentes)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(tipoLabel(t)),
                          selected: _tipo == t,
                          onSelected: (sel) => setState(() => _tipo = sel ? t : null),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (_isAdmin) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mostrar locais desativados', style: TextStyle(fontWeight: FontWeight.w600)),
                value: _showInactive,
                onChanged: (v) {
                  setState(() => _showInactive = v);
                  _load();
                },
              ),
            ],
            const SizedBox(height: 14),
            if (_loading)
              const SkeletonList(count: 4, height: 104)
            else if (_error != null && _sites.isEmpty)
              ErrorState(message: _error!, onRetry: _load)
            else if (items.isEmpty)
              EmptyState(
                icon: Icons.explore_outlined,
                title: _sites.isEmpty ? 'Nenhum Dive Site ainda' : 'Nada encontrado',
                message: _sites.isEmpty
                    ? (_isAdmin
                        ? 'Cadastre o primeiro ponto de mergulho para os usuários.'
                        : 'Os pontos de mergulho cadastrados pela equipe aparecerão aqui.')
                    : 'Tente outro termo de busca ou limpe os filtros.',
                actionLabel: _sites.isEmpty && _isAdmin ? 'Cadastrar Dive Site' : null,
                onAction: _sites.isEmpty && _isAdmin ? _create : null,
              )
            else
              ...items.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SiteCard(site: s, onTap: () => _open(s)),
                  )),
          ],
        ),
      ),
    );
  }
}

class _SiteCard extends StatelessWidget {
  final DiveSiteModel site;
  final VoidCallback onTap;
  const _SiteCard({required this.site, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: site.ativo ? 1 : .6,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DiverrTheme.radius),
          boxShadow: DiverrTheme.softShadow,
        ),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 104,
              child: Row(
                children: [
                  SizedBox(
                    width: 104,
                    height: 104,
                    child: RemoteImage(
                      url: site.coverUrl,
                      cacheKey: site.images.isEmpty ? null : site.images.first.id,
                      placeholderIcon: Icons.location_on,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            site.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            site.localizacao.isEmpty ? '—' : site.localizacao,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: DiverrTheme.muted, fontSize: 12.5),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (site.tipo != null) InfoChip(text: tipoLabel(site.tipo)),
                              if (site.profundidadeMaxima != null)
                                InfoChip(
                                  icon: Icons.arrow_downward,
                                  text: '${site.profundidadeMaxima!.toStringAsFixed(0)} m',
                                  color: DiverrTheme.secondary,
                                ),
                              if (!site.ativo)
                                const InfoChip(icon: Icons.block, text: 'Desativado', color: DiverrTheme.danger),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.chevron_right, color: DiverrTheme.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
