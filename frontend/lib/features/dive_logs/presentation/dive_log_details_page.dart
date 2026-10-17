import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme.dart';
import '../../../core/events.dart';
import '../../../core/format.dart';
import '../../../core/images/image_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/ui/widgets.dart';
import '../../auth/data/me_api.dart';
import '../../social/presentation/public_profile_page.dart';
import '../../social/presentation/social_widgets.dart';
import '../data/dive_log_model.dart';
import '../data/dive_logs_api.dart';
import 'dive_log_form_page.dart';

/// Detalhes de um mergulho. Ao voltar devolve true se algo mudou (para a lista recarregar).
class DiveLogDetailsPage extends StatefulWidget {
  final DiveLogModel log;
  const DiveLogDetailsPage({super.key, required this.log});

  @override
  State<DiveLogDetailsPage> createState() => _DiveLogDetailsPageState();
}

class _DiveLogDetailsPageState extends State<DiveLogDetailsPage> {
  final _api = DiveLogsApi();
  final _images = ImageService();

  late DiveLogModel _log;
  bool _changed = false;
  bool _busy = false;

  bool get _isOwner => _log.ownerId == (AppSession.instance.currentUser?.id ?? -1);
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _log = widget.log;
  }

  Future<void> _edit() async {
    final saved = await openDiveLogForm(context, existing: _log);
    if (!saved || !mounted) return;
    try {
      final fresh = await _api.findById(_log.id);
      if (!mounted) return;
      setState(() {
        _log = fresh;
        _changed = true;
      });
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'Excluir mergulho?',
      message: 'O mergulho em ${_log.diveSiteNome} e suas fotos serão apagados. Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok) return;

    setState(() => _busy = true);
    try {
      await _api.delete(_log.id);
      AppEvents.notifyDiveLogsChanged();
      await MeApi().refresh();
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, e.message, error: true);
    }
  }

  Future<void> _addPhoto() async {
    final ent = AppSession.instance.entitlements;
    if (_log.imagens.length >= ent.maxPhotosPerLog) {
      if (!ent.isPremium) {
        await showUpgradeSheet(
          context,
          message: 'O plano Free permite até ${ent.maxPhotosPerLog} fotos por mergulho.',
        );
      } else {
        showSnack(context, 'Limite de ${ent.maxPhotosPerLog} fotos por mergulho.', error: true);
      }
      return;
    }

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
      final json = await _images.upload('/api/dive-logs/${_log.id}', file);
      if (!mounted) return;
      setState(() {
        _log = DiveLogModel.fromJson(json);
        _busy = false;
        _changed = true;
        _page = 0;
      });
      AppEvents.notifyDiveLogsChanged();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (e.isPlanLimit) {
        showUpgradeSheet(context, message: e.message);
      } else {
        showSnack(context, e.message, error: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, 'Não foi possível adicionar a foto.', error: true);
    }
  }

  Future<void> _removePhoto(int index) async {
    final ok = await confirmDialog(
      context,
      title: 'Remover foto?',
      message: 'Esta foto será excluída do mergulho.',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!ok) return;

    setState(() => _busy = true);
    try {
      final updated = await _api.removeImage(_log.id, _log.imagens[index].id);
      if (!mounted) return;
      setState(() {
        _log = updated;
        _busy = false;
        _changed = true;
        _page = 0;
      });
      AppEvents.notifyDiveLogsChanged();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, e.message, error: true);
    }
  }

  Widget _gallery() {
    final imgs = _log.imagens;
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
            onLongPress: _isOwner ? () => _removePhoto(i) : null,
            child: RemoteImage(url: imgs[i].url, cacheKey: imgs[i].id),
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

  Widget _tile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DiverrTheme.radiusSmall),
        border: Border.all(color: DiverrTheme.dark.withOpacity(.06)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: DiverrTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: DiverrTheme.muted)),
                const SizedBox(height: 2),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownerCard(DiveLogModel l) {
    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PublicProfilePage(userId: l.ownerId)),
        ),
        leading: UserAvatar(name: l.ownerNome),
        title: Text(l.ownerNome, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: l.ownerUsername == null ? null : Text('@${l.ownerUsername}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _ratingRow(String label, String hint, double? v) {
    final has = v != null && v > 0;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(hint, style: const TextStyle(fontSize: 12, color: DiverrTheme.muted)),
            ],
          ),
        ),
        if (has) ...[
          RatingStars(value: v, size: 20),
          const SizedBox(width: 8),
          Text(formatRating(v), style: const TextStyle(fontWeight: FontWeight.w900)),
        ] else
          const Text('—', style: TextStyle(color: DiverrTheme.muted)),
      ],
    );
  }

  Widget _ratingsBlock(DiveLogModel l) {
    final hasLocal = (l.notaLocal ?? 0) > 0;
    final hasExp = (l.notaExperiencia ?? 0) > 0;
    if (!hasLocal && !hasExp) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DiverrTheme.radius),
        boxShadow: DiverrTheme.softShadow,
      ),
      child: Column(
        children: [
          _ratingRow('Local do mergulho', 'Nota dada ao Dive Site', l.notaLocal),
          const Divider(height: 22),
          _ratingRow('Minha experiência', 'O quanto o mergulho foi bom', l.notaExperiencia),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = _log;
    final consumo = l.consumoBar;

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
                  title: Text(l.diveSiteNome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  actions: !_isOwner ? null : [
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') _edit();
                        if (v == 'photo') _addPhoto();
                        if (v == 'delete') _delete();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar'), contentPadding: EdgeInsets.zero)),
                        PopupMenuItem(value: 'photo', child: ListTile(leading: Icon(Icons.add_a_photo_outlined), title: Text('Adicionar foto'), contentPadding: EdgeInsets.zero)),
                        PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: DiverrTheme.danger), title: Text('Excluir', style: TextStyle(color: DiverrTheme.danger)), contentPadding: EdgeInsets.zero)),
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
                        if (!_isOwner) ...[
                          _ownerCard(l),
                          const SizedBox(height: 14),
                        ],
                        Row(
                          children: [
                            const Icon(Icons.event_outlined, size: 18, color: DiverrTheme.muted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                formatDateTime(l.dataHora),
                                style: const TextStyle(color: DiverrTheme.muted, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _ratingsBlock(l),
                        const SizedBox(height: 20),
                        GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            mainAxisExtent: 74,
                          ),
                          children: [
                            _tile(Icons.timer_outlined, 'Duração', formatDuration(l.duracaoMinutos)),
                            _tile(Icons.arrow_downward, 'Prof. máxima', formatMeters(l.profundidadeMaxima)),
                            _tile(Icons.swap_vert, 'Prof. média', formatMeters(l.profundidadeMedia)),
                            _tile(Icons.visibility_outlined, 'Visibilidade', formatMeters(l.visibilidade)),
                            _tile(Icons.thermostat_outlined, 'Temp. da água', formatNumber(l.temperaturaAgua, '°C')),
                            _tile(Icons.water_outlined, 'Corrente', labelOf(kCorrenteLabels, l.corrente)),
                            _tile(Icons.air, 'Mistura', labelOf(kGasLabels, l.tipoGas)),
                            _tile(Icons.speed, 'Consumo', consumo == null ? '—' : '$consumo bar'),
                            _tile(Icons.opacity, 'Água', labelOf(kAguaLabels, l.tipoAgua)),
                            _tile(Icons.directions_boat_outlined, 'Entrada', labelOf(kEntradaLabels, l.tipoEntrada)),
                          ],
                        ),
                        if (l.observacoes != null && l.observacoes!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const SectionTitle('Anotações'),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Text(l.observacoes!, style: const TextStyle(height: 1.5)),
                            ),
                          ),
                        ],
                        if (l.comentarioLocal != null && l.comentarioLocal!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const SectionTitle('Comentário sobre o local'),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Text(l.comentarioLocal!, style: const TextStyle(height: 1.5)),
                            ),
                          ),
                        ],
                        if (l.imagens.isNotEmpty && _isOwner) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Toque na foto para ampliar. Segure para remover.',
                            style: TextStyle(color: DiverrTheme.muted, fontSize: 12.5),
                          ),
                        ],
                        const SizedBox(height: 24),
                        DiveLogSocialSection(logId: l.id),
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
