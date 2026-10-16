import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme.dart';
import '../../../core/events.dart';
import '../../../core/format.dart';
import '../../../core/images/image_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/ui/widgets.dart';
import '../../dive_logs/data/dive_log_model.dart';
import '../../dive_logs/data/dive_logs_api.dart';
import '../../dive_logs/presentation/dive_log_details_page.dart';
import '../../dive_logs/presentation/dive_log_form_page.dart';
import '../../lists/data/lists_api.dart';
import '../../lists/presentation/list_widgets.dart';
import '../../reviews/presentation/site_reviews_section.dart';
import '../data/dive_site_model.dart';
import '../data/dive_sites_api.dart';
import 'create_dive_site_page.dart';

/// Detalhes do Dive Site. Admin pode editar, desativar e gerenciar fotos.
/// Ao voltar devolve true se o site mudou (a lista recarrega).
class DiveSiteDetailsPage extends StatefulWidget {
  final DiveSiteModel site;
  const DiveSiteDetailsPage({super.key, required this.site});

  @override
  State<DiveSiteDetailsPage> createState() => _DiveSiteDetailsPageState();
}

class _DiveSiteDetailsPageState extends State<DiveSiteDetailsPage> {
  final _sitesApi = DiveSitesApi();
  final _logsApi = DiveLogsApi();
  final _images = ImageService();

  late DiveSiteModel _site;
  List<DiveLogModel> _myLogs = [];
  bool _loadingLogs = true;
  bool _changed = false;
  bool _busy = false;
  int _page = 0;
  bool _inWishlist = false;
  bool _wishBusy = false;

  bool get _isAdmin => AppSession.instance.isAdmin;

  @override
  void initState() {
    super.initState();
    _site = widget.site;
    _loadMyLogs();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      final w = await ListsApi().wishlist();
      if (mounted) setState(() => _inWishlist = w.containsSite(_site.id));
    } on ApiException {
      // sem conexão: o marcador só não reflete o estado
    }
  }

  Future<void> _toggleWishlist() async {
    if (_wishBusy) return;
    setState(() => _wishBusy = true);
    try {
      final api = ListsApi();
      final list = _inWishlist
          ? await api.removeFromWishlist(_site.id)
          : await api.addToWishlist(_site.id);
      AppEvents.notifyListsChanged();
      if (!mounted) return;
      setState(() {
        _inWishlist = list.containsSite(_site.id);
        _wishBusy = false;
      });
      showSnack(context, _inWishlist ? 'Adicionado a "Quero mergulhar".' : 'Removido de "Quero mergulhar".');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _wishBusy = false);
      showSnack(context, e.message, error: true);
    }
  }

  Future<void> _loadMyLogs() async {
    try {
      final logs = await _logsApi.findMineBySite(_site.id);
      if (!mounted) return;
      setState(() {
        _myLogs = logs;
        _loadingLogs = false;
      });
    } on ApiException {
      if (mounted) setState(() => _loadingLogs = false);
    }
  }

  // ------------------------------------------------------------ ações de usuário

  Future<void> _registerDive() async {
    final saved = await openDiveLogForm(context, site: _site);
    if (saved) _loadMyLogs();
  }

  Future<void> _openLog(DiveLogModel log) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DiveLogDetailsPage(log: log)),
    );
    if (changed == true) _loadMyLogs();
  }

  // ------------------------------------------------------------ ações de admin

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<DiveSiteModel>(
      MaterialPageRoute(builder: (_) => CreateDiveSitePage(site: _site)),
    );
    if (updated != null && mounted) {
      setState(() {
        _site = updated;
        _changed = true;
      });
    }
  }

  Future<void> _toggleActive() async {
    final deactivating = _site.ativo;
    final ok = await confirmDialog(
      context,
      title: deactivating ? 'Desativar Dive Site?' : 'Reativar Dive Site?',
      message: deactivating
          ? 'Usuários não verão mais este local nem poderão registrar novos mergulhos nele. Mergulhos já registrados continuam salvos.'
          : 'O local voltará a aparecer para todos os usuários.',
      confirmLabel: deactivating ? 'Desativar' : 'Reativar',
      destructive: deactivating,
    );
    if (!ok) return;

    setState(() => _busy = true);
    try {
      final updated = await _sitesApi.setAtivo(_site.id, !_site.ativo);
      if (!mounted) return;
      setState(() {
        _site = updated;
        _busy = false;
        _changed = true;
      });
      showSnack(context, deactivating ? 'Dive Site desativado.' : 'Dive Site reativado.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, e.message, error: true);
    }
  }

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final file = await _images.pick(source);
      if (file == null || !mounted) return;

      setState(() => _busy = true);
      final json = await _images.upload('/api/dive-sites/${_site.id}', file);
      if (!mounted) return;
      setState(() {
        _site = DiveSiteModel.fromJson(json);
        _busy = false;
        _changed = true;
        _page = 0;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, e.message, error: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, 'Não foi possível adicionar a foto.', error: true);
    }
  }

  Future<void> _removePhoto(int index) async {
    if (!_isAdmin) return;
    final ok = await confirmDialog(
      context,
      title: 'Remover foto?',
      message: 'Esta foto será excluída do Dive Site.',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!ok) return;

    setState(() => _busy = true);
    try {
      final updated = await _sitesApi.removeImage(_site.id, _site.images[index].id);
      if (!mounted) return;
      setState(() {
        _site = updated;
        _busy = false;
        _changed = true;
        _page = 0;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, e.message, error: true);
    }
  }

  // ------------------------------------------------------------ UI

  Widget _gallery() {
    final imgs = _site.images;
    if (imgs.isEmpty) {
      return Container(
        decoration: const BoxDecoration(gradient: DiverrTheme.oceanGradient),
        child: const Center(child: Icon(Icons.scuba_diving, size: 84, color: Colors.white70)),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: imgs.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => openImageViewer(
              context,
              imgs.map((e) => e.url).toList(),
              imgs.map((e) => e.id).toList(),
              i,
            ),
            onLongPress: _isAdmin ? () => _removePhoto(i) : null,
            child: RemoteImage(url: imgs[i].url, cacheKey: imgs[i].id),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black26, Colors.transparent, Colors.black26],
                ),
              ),
            ),
          ),
        ),
        if (imgs.length > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imgs.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _page ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _myLogsSection() {
    if (_loadingLogs) return const SkeletonList(count: 1, height: 70);
    if (_myLogs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DiverrTheme.radius),
        ),
        child: const Text(
          'Você ainda não registrou mergulhos neste local.',
          style: TextStyle(color: DiverrTheme.muted),
        ),
      );
    }
    return Column(
      children: _myLogs
          .map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    onTap: () => _openLog(l),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x228ED8E5),
                      child: Icon(Icons.scuba_diving, color: DiverrTheme.primary),
                    ),
                    title: Text(formatDateTime(l.dataHora), style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${formatMeters(l.profundidadeMaxima)} · ${formatDuration(l.duracaoMinutos)}'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _site;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 280,
                  backgroundColor: DiverrTheme.primary,
                  foregroundColor: Colors.white,
                  title: Text(s.nome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  actions: [
                    IconButton(
                      onPressed: _wishBusy ? null : _toggleWishlist,
                      tooltip: _inWishlist ? 'Remover de "Quero mergulhar"' : 'Quero mergulhar aqui',
                      icon: Icon(_inWishlist ? Icons.bookmark : Icons.bookmark_border),
                    ),
                    if (_isAdmin)
                      PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _edit();
                          if (v == 'photo') _addPhoto();
                          if (v == 'toggle') _toggleActive();
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar'), contentPadding: EdgeInsets.zero)),
                          const PopupMenuItem(value: 'photo', child: ListTile(leading: Icon(Icons.add_a_photo_outlined), title: Text('Adicionar foto'), contentPadding: EdgeInsets.zero)),
                          PopupMenuItem(
                            value: 'toggle',
                            child: ListTile(
                              leading: Icon(s.ativo ? Icons.block : Icons.check_circle_outline,
                                  color: s.ativo ? DiverrTheme.danger : DiverrTheme.success),
                              title: Text(s.ativo ? 'Desativar' : 'Reativar',
                                  style: TextStyle(color: s.ativo ? DiverrTheme.danger : DiverrTheme.success)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(background: _gallery()),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (s.localizacao.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 18, color: DiverrTheme.muted),
                              const SizedBox(width: 6),
                              Expanded(child: Text(s.localizacao, style: const TextStyle(color: DiverrTheme.muted, fontWeight: FontWeight.w600))),
                            ],
                          ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            InfoChip(icon: Icons.category_outlined, text: tipoLabel(s.tipo)),
                            if (s.nivel != null)
                              InfoChip(icon: Icons.stairs_outlined, text: nivelLabel(s.nivel), color: DiverrTheme.success),
                            if (s.ratingAverage != null)
                              InfoChip(
                                icon: Icons.star_rounded,
                                text: '${s.ratingAverage!.toStringAsFixed(1)} (${s.ratingCount})',
                                color: DiverrTheme.gold,
                              ),
                            if (s.profundidadeMaxima != null)
                              InfoChip(icon: Icons.arrow_downward, text: 'até ${formatMeters(s.profundidadeMaxima)}', color: DiverrTheme.secondary),
                            if (!s.ativo) const InfoChip(icon: Icons.block, text: 'Desativado', color: DiverrTheme.danger),
                          ],
                        ),
                        if (s.descricao != null && s.descricao!.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          const SectionTitle('Sobre o local'),
                          Text(s.descricao!, style: const TextStyle(height: 1.5)),
                        ],
                        const SizedBox(height: 22),
                        const SectionTitle('Localização'),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(DiverrTheme.radius),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.my_location, color: DiverrTheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${s.latitude.toStringAsFixed(6)}, ${s.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (s.extended != null && !s.extended!.isEmpty) ...[
                          const SizedBox(height: 22),
                          SectionTitle(
                            'Informações do local',
                            trailing: const PlanBadge(premium: true),
                          ),
                          _ExtendedInfoCard(info: s.extended!),
                        ] else if (s.extendedLocked) ...[
                          const SizedBox(height: 22),
                          const _LockedInfoCard(),
                        ],
                        if (s.hiddenImages > 0) ...[
                          const SizedBox(height: 16),
                          _LockedPhotosBanner(hidden: s.hiddenImages),
                        ],
                        if (s.images.length > 1) ...[
                          const SizedBox(height: 22),
                          SectionTitle(
                            'Fotos',
                            trailing: _isAdmin
                                ? const Text('segure para remover', style: TextStyle(fontSize: 12, color: DiverrTheme.muted))
                                : null,
                          ),
                          SizedBox(
                            height: 92,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: s.images.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (_, i) => GestureDetector(
                                onTap: () => openImageViewer(
                                  context,
                                  s.images.map((e) => e.url).toList(),
                                  s.images.map((e) => e.id).toList(),
                                  i,
                                ),
                                onLongPress: _isAdmin ? () => _removePhoto(i) : null,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: RemoteImage(
                                    url: s.images[i].url,
                                    cacheKey: s.images[i].id,
                                    width: 92,
                                    height: 92,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        const SectionTitle('Avaliações'),
                        SiteReviewsSection(siteId: s.id, canReview: s.ativo),
                        const SizedBox(height: 22),
                        const SectionTitle('Meus mergulhos aqui'),
                        _myLogsSection(),
                        const SizedBox(height: 26),
                        if (s.ativo)
                          FilledButton.icon(
                            onPressed: _registerDive,
                            icon: const Icon(Icons.scuba_diving),
                            label: const Text('Registrar mergulho aqui'),
                          ),
                        if (s.ativo) ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => showAddToListSheet(context, s.id),
                            icon: const Icon(Icons.playlist_add),
                            label: const Text('Adicionar a uma lista'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_busy)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExtendedInfoCard extends StatelessWidget {
  final SiteExtended info;
  const _ExtendedInfoCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, String?)>[
      (Icons.event_outlined, 'Melhor época', info.melhorEpoca),
      (Icons.visibility_outlined, 'Visibilidade típica', info.visibilidadeTipica),
      (Icons.thermostat_outlined, 'Temperatura da água', info.temperaturaAgua),
      (Icons.water_outlined, 'Corrente típica', info.correnteTipica),
      (Icons.workspace_premium_outlined, 'Certificação mínima', info.certificacaoMinima),
      (Icons.set_meal_outlined, 'Fauna e flora', info.faunaFlora),
      (Icons.directions_outlined, 'Como chegar', info.comoChegar),
      (Icons.store_mall_directory_outlined, 'Infraestrutura', info.infraestrutura),
      (Icons.lightbulb_outline, 'Dicas', info.dicas),
      (Icons.warning_amber_rounded, 'Avisos de segurança', info.avisosSeguranca),
    ].where((r) => r.$3 != null && r.$3!.trim().isNotEmpty).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    rows[i].$1,
                    size: 22,
                    color: rows[i].$2 == 'Avisos de segurança' ? DiverrTheme.warning : DiverrTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rows[i].$2, style: const TextStyle(fontSize: 12.5, color: DiverrTheme.muted, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(rows[i].$3!, style: const TextStyle(height: 1.45)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LockedInfoCard extends StatelessWidget {
  const _LockedInfoCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: DiverrTheme.gold.withOpacity(.16), shape: BoxShape.circle),
              child: const Icon(Icons.lock_outline, color: DiverrTheme.gold),
            ),
            const SizedBox(height: 12),
            const Text('Mais informações sobre este local', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 6),
            const Text(
              'Melhor época, visibilidade, temperatura, fauna, como chegar, dicas e avisos de segurança '
              'estão disponíveis para assinantes Premium.',
              textAlign: TextAlign.center,
              style: TextStyle(color: DiverrTheme.muted, height: 1.4),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => showUpgradeSheet(context),
              icon: const Icon(Icons.workspace_premium),
              label: const Text('Conhecer o Premium'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedPhotosBanner extends StatelessWidget {
  final int hidden;
  const _LockedPhotosBanner({required this.hidden});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showUpgradeSheet(context),
      borderRadius: BorderRadius.circular(DiverrTheme.radiusSmall),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DiverrTheme.gold.withOpacity(.12),
          borderRadius: BorderRadius.circular(DiverrTheme.radiusSmall),
        ),
        child: Row(
          children: [
            const Icon(Icons.photo_library_outlined, color: DiverrTheme.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '+$hidden ${hidden == 1 ? 'foto' : 'fotos'} deste local no Premium',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.chevron_right, color: DiverrTheme.muted),
          ],
        ),
      ),
    );
  }
}
