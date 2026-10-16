import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme.dart';
import '../../../core/events.dart';
import '../../../core/format.dart';
import '../../../core/images/image_service.dart';
import '../../../core/models/image_ref.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/ui/widgets.dart';
import '../../auth/data/me_api.dart';
import '../../home/data/dive_site_model.dart';
import '../data/dive_log_model.dart';
import '../data/dive_logs_api.dart';
import 'dive_site_picker_page.dart';

/// Abre o formulário respeitando o limite do plano. Retorna true se algo foi salvo.
Future<bool> openDiveLogForm(
  BuildContext context, {
  DiveLogModel? existing,
  DiveSiteModel? site,
}) async {
  // Mergulhos são ilimitados em todos os planos: não há checagem de limite aqui.
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => DiveLogFormPage(existing: existing, initialSite: site),
    ),
  );
  return result == true;
}

/// Foto escolhida, ainda não enviada. Os bytes ficam em memória só para a miniatura.
class _PickedImage {
  final XFile file;
  final Uint8List bytes;
  _PickedImage(this.file, this.bytes);
}

class DiveLogFormPage extends StatefulWidget {
  final DiveLogModel? existing;
  final DiveSiteModel? initialSite;

  const DiveLogFormPage({super.key, this.existing, this.initialSite});

  @override
  State<DiveLogFormPage> createState() => _DiveLogFormPageState();
}

class _DiveLogFormPageState extends State<DiveLogFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _api = DiveLogsApi();
  final _images = ImageService();

  String? _siteId;
  String? _siteName;
  late DateTime _dateTime;

  final _duracao = TextEditingController();
  final _profMax = TextEditingController();
  final _profMedia = TextEditingController();
  final _visib = TextEditingController();
  final _temp = TextEditingController();
  final _pIni = TextEditingController();
  final _pFim = TextEditingController();
  final _obs = TextEditingController();

  String? _corrente;
  String? _agua;
  String? _entrada;
  String? _gas;
  int _rating = 0;

  List<ImageRef> _existingImages = [];
  final List<_PickedImage> _newImages = [];

  bool _saving = false;
  String _progress = '';

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _siteId = e.diveSiteId;
      _siteName = e.diveSiteNome;
      _dateTime = e.dataHora;
      _duracao.text = e.duracaoMinutos?.toString() ?? '';
      _profMax.text = _fmt(e.profundidadeMaxima);
      _profMedia.text = _fmt(e.profundidadeMedia);
      _visib.text = _fmt(e.visibilidade);
      _temp.text = _fmt(e.temperaturaAgua);
      _pIni.text = e.pressaoInicial?.toString() ?? '';
      _pFim.text = e.pressaoFinal?.toString() ?? '';
      _obs.text = e.observacoes ?? '';
      _corrente = e.corrente;
      _agua = e.tipoAgua;
      _entrada = e.tipoEntrada;
      _gas = e.tipoGas;
      _rating = e.avaliacao ?? 0;
      _existingImages = List.of(e.imagens);
    } else {
      _dateTime = DateTime.now();
      _siteId = widget.initialSite?.id;
      _siteName = widget.initialSite?.nome;
    }
  }

  @override
  void dispose() {
    for (final c in [_duracao, _profMax, _profMedia, _visib, _temp, _pIni, _pFim, _obs]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _fmt(double? v) {
    if (v == null) return '';
    return v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toString();
  }

  // ------------------------------------------------------------ ações

  Future<void> _pickSite() async {
    final site = await Navigator.of(context).push<DiveSiteModel>(
      MaterialPageRoute(builder: (_) => DiveSitePickerPage(selectedId: _siteId)),
    );
    if (site != null) {
      setState(() {
        _siteId = site.id;
        _siteName = site.nome;
      });
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(1960),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null) return;

    setState(() {
      _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  int get _photoCount => _existingImages.length + _newImages.length;

  Future<void> _addPhotos() async {
    final ent = AppSession.instance.entitlements;
    final remaining = ent.maxPhotosPerLog - _photoCount;

    if (remaining <= 0) {
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
      if (source == ImageSource.camera) {
        final file = await _images.pick(ImageSource.camera);
        if (file != null) {
          final bytes = await file.readAsBytes();
          if (mounted) setState(() => _newImages.add(_PickedImage(file, bytes)));
        }
      } else {
        final files = await _images.pickMany();
        if (files.isNotEmpty) {
          final picked = <_PickedImage>[];
          for (final f in files.take(remaining)) {
            picked.add(_PickedImage(f, await f.readAsBytes()));
          }
          if (!mounted) return;
          setState(() => _newImages.addAll(picked));
          if (files.length > remaining) {
            showSnack(context, 'Só ${remaining == 1 ? '1 foto cabe' : '$remaining fotos cabem'} no seu plano.');
          }
        }
      }
    } catch (_) {
      if (mounted) showSnack(context, 'Não foi possível acessar as fotos. Verifique as permissões.', error: true);
    }
  }

  Future<void> _removeExisting(ImageRef image) async {
    final ok = await confirmDialog(
      context,
      title: 'Remover foto?',
      message: 'Esta foto será excluída do mergulho.',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!ok || widget.existing == null) return;

    try {
      final updated = await _api.removeImage(widget.existing!.id, image.id);
      if (!mounted) return;
      setState(() => _existingImages = List.of(updated.imagens));
      AppEvents.notifyDiveLogsChanged();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Map<String, dynamic> _buildBody() => {
        'diveSiteId': _siteId,
        'dataHora': _dateTime.toIso8601String(),
        'duracaoMinutos': parseInt(_duracao.text),
        'profundidadeMaxima': parseDouble(_profMax.text),
        'profundidadeMedia': parseDouble(_profMedia.text),
        'visibilidade': parseDouble(_visib.text),
        'temperaturaAgua': parseDouble(_temp.text),
        'corrente': _corrente,
        'tipoAgua': _agua,
        'tipoEntrada': _entrada,
        'tipoGas': _gas,
        'pressaoInicial': parseInt(_pIni.text),
        'pressaoFinal': parseInt(_pFim.text),
        'avaliacao': _rating == 0 ? null : _rating,
        'observacoes': _obs.text.trim().isEmpty ? null : _obs.text.trim(),
      };

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_siteId == null) {
      showSnack(context, 'Selecione o Dive Site do mergulho.', error: true);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _saving = true;
      _progress = 'Salvando mergulho…';
    });

    try {
      final saved = _isEdit
          ? await _api.update(widget.existing!.id, _buildBody())
          : await _api.create(_buildBody());

      var failed = 0;
      for (var i = 0; i < _newImages.length; i++) {
        if (mounted) setState(() => _progress = 'Enviando foto ${i + 1} de ${_newImages.length}…');
        try {
          await _images.upload('/api/dive-logs/${saved.id}', _newImages[i].file);
        } on ApiException {
          failed++;
        }
      }

      AppEvents.notifyDiveLogsChanged();
      await MeApi().refresh();

      if (!mounted) return;
      navigator.pop(true);

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            failed > 0
                ? 'Mergulho salvo, mas $failed foto(s) não foram enviadas. Abra o mergulho para tentar de novo.'
                : (_isEdit ? 'Mergulho atualizado!' : 'Mergulho registrado!'),
          ),
        ));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (e.isPlanLimit) {
        showUpgradeSheet(context, message: e.message);
      } else {
        showSnack(context, e.message, error: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSnack(context, 'Não foi possível salvar. Tente novamente.', error: true);
    }
  }

  // ------------------------------------------------------------ UI

  String? _optionalNumber(String? v, {double? max, bool integer = false}) {
    if (v == null || v.trim().isEmpty) return null;
    final n = integer ? parseInt(v)?.toDouble() : parseDouble(v);
    if (n == null) return 'Valor inválido';
    if (n < 0) return 'Não pode ser negativo';
    if (max != null && n > max) return 'Máximo $max';
    return null;
  }

  Widget _numField(
    TextEditingController c,
    String label, {
    String? suffix,
    double? max,
    bool integer = false,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.numberWithOptions(decimal: !integer),
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: (v) => _optionalNumber(v, max: max, integer: integer),
    );
  }

  Widget _choice(String title, Map<String, String> options, String? value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: DiverrTheme.muted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries
              .map((e) => ChoiceChip(
                    label: Text(e.value),
                    selected: value == e.key,
                    onSelected: (sel) => onChanged(sel ? e.key : null),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DiverrTheme.radiusSmall),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DiverrTheme.background,
          borderRadius: BorderRadius.circular(DiverrTheme.radiusSmall),
        ),
        child: Row(
          children: [
            Icon(icon, color: DiverrTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: DiverrTheme.muted)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: DiverrTheme.muted),
          ],
        ),
      ),
    );
  }

  Widget _photoThumb({required Widget image, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(width: 92, height: 92, child: image),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ent = AppSession.instance.entitlements;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Editar mergulho' : 'Novo mergulho')),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                _section('Local e data', [
                  _tile(
                    icon: Icons.location_on_outlined,
                    label: 'Dive Site',
                    value: _siteName ?? 'Selecionar local',
                    onTap: _pickSite,
                  ),
                  const SizedBox(height: 10),
                  _tile(
                    icon: Icons.event_outlined,
                    label: 'Data e hora',
                    value: formatDateTime(_dateTime),
                    onTap: _pickDateTime,
                  ),
                ]),
                _section('Dados do mergulho', [
                  _numField(_duracao, 'Duração', suffix: 'min', max: 1440, integer: true),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _numField(_profMax, 'Prof. máxima', suffix: 'm', max: 400)),
                      const SizedBox(width: 12),
                      Expanded(child: _numField(_profMedia, 'Prof. média', suffix: 'm', max: 400)),
                    ],
                  ),
                ]),
                _section('Condições', [
                  Row(
                    children: [
                      Expanded(child: _numField(_visib, 'Visibilidade', suffix: 'm', max: 200)),
                      const SizedBox(width: 12),
                      Expanded(child: _numField(_temp, 'Temp. da água', suffix: '°C', max: 50)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _choice('Corrente', kCorrenteLabels, _corrente, (v) => setState(() => _corrente = v)),
                  const SizedBox(height: 16),
                  _choice('Tipo de água', kAguaLabels, _agua, (v) => setState(() => _agua = v)),
                  const SizedBox(height: 16),
                  _choice('Entrada', kEntradaLabels, _entrada, (v) => setState(() => _entrada = v)),
                ]),
                _section('Gás e consumo', [
                  _choice('Mistura', kGasLabels, _gas, (v) => setState(() => _gas = v)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _numField(_pIni, 'Pressão inicial', suffix: 'bar', max: 400, integer: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _numField(_pFim, 'Pressão final', suffix: 'bar', max: 400, integer: true)),
                    ],
                  ),
                ]),
                _section('Avaliação e anotações', [
                  const Text('Como foi o mergulho?', style: TextStyle(color: DiverrTheme.muted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  RatingStars(value: _rating, size: 36, onChanged: (v) => setState(() => _rating = v)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _obs,
                    maxLines: 4,
                    maxLength: 3000,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      alignLabelWithHint: true,
                      hintText: 'O que você viu? Como foi a experiência?',
                    ),
                  ),
                ]),
                _section('Fotos ($_photoCount/${ent.maxPhotosPerLog})', [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final img in _existingImages)
                        _photoThumb(
                          image: RemoteImage(url: img.url, cacheKey: img.id),
                          onRemove: () => _removeExisting(img),
                        ),
                      for (final picked in _newImages)
                        _photoThumb(
                          image: Image.memory(picked.bytes, fit: BoxFit.cover),
                          onRemove: () => setState(() => _newImages.remove(picked)),
                        ),
                      InkWell(
                        onTap: _addPhotos,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: DiverrTheme.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: DiverrTheme.primary.withOpacity(.35)),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: DiverrTheme.primary),
                              SizedBox(height: 4),
                              Text('Adicionar', style: TextStyle(fontSize: 12, color: DiverrTheme.primary, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!ent.isPremium) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Plano Free: até ${ent.maxPhotosPerLog} fotos por mergulho.',
                      style: const TextStyle(fontSize: 12.5, color: DiverrTheme.muted),
                    ),
                  ],
                ]),
              ],
            ),
          ),
          if (_saving)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(.35),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(_progress, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: LoadingButton(
            loading: _saving,
            onPressed: _save,
            label: _isEdit ? 'Salvar alterações' : 'Registrar mergulho',
            icon: Icons.check,
          ),
        ),
      ),
    );
  }
}
