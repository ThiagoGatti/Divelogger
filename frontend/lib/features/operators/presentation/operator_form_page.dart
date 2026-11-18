import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme.dart';
import '../../../core/events.dart';
import '../../../core/images/image_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ui/widgets.dart';
import '../data/operator_models.dart';
import '../data/operators_api.dart';
import 'sites_multi_picker_page.dart';

/// Cadastro e edição de operadora (somente ADMIN): nome, endereço, foto e locais onde atua.
class OperatorFormPage extends StatefulWidget {
  final OperatorDetail? existing;
  const OperatorFormPage({super.key, this.existing});

  @override
  State<OperatorFormPage> createState() => _OperatorFormPageState();
}

class _OperatorFormPageState extends State<OperatorFormPage> {
  final _api = OperatorsApi();
  final _images = ImageService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nome = TextEditingController(text: widget.existing?.nome ?? '');

  late Set<String> _siteIds = {...?widget.existing?.sites.map((s) => s.id)};
  late Map<String, String> _siteNames = {for (final s in widget.existing?.sites ?? const <SiteRef>[]) s.id: s.nome};
  late bool _ativo = widget.existing?.ativo ?? true;

  XFile? _newPhoto;
  Uint8List? _newPhotoBytes;
  bool _removePhoto = false;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
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
      final f = await _images.pick(source);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      if (!mounted) return;
      setState(() {
        _newPhoto = f;
        _newPhotoBytes = bytes;
        _removePhoto = false;
      });
    } catch (_) {
      if (mounted) showSnack(context, 'Não foi possível acessar a foto.', error: true);
    }
  }

  Future<void> _pickSites() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (_) => SitesMultiPickerPage(
          selectedIds: _siteIds,
          initialNames: _siteNames,
          title: 'Onde esta operadora atua',
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _siteIds = result.keys.toSet();
        _siteNames = result;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final nome = _nome.text.trim();

    setState(() => _saving = true);
    try {
      var detail = _isEdit
          ? await _api.update(widget.existing!.id, nome)
          : await _api.create(nome);

      if (_isEdit && _ativo != widget.existing!.ativo) {
        detail = await _api.setAtivo(detail.id, _ativo);
      }

      final before = {...?widget.existing?.sites.map((s) => s.id)};
      if (!_isEdit || before.length != _siteIds.length || !before.containsAll(_siteIds)) {
        detail = await _api.setSites(detail.id, _siteIds.toList());
      }

      String? photoError;
      if (_removePhoto && _newPhoto == null && widget.existing?.photoUrl != null) {
        detail = await _api.removePhoto(detail.id);
      }
      if (_newPhoto != null) {
        try {
          detail = await _api.uploadPhoto(detail.id, _newPhoto!);
        } on ApiException catch (e) {
          photoError = e.message;
        }
      }

      AppEvents.notifyDiveSitesChanged(); // os locais vinculados passam a mostrar a operadora

      if (!mounted) return;
      Navigator.pop(context, detail);
      if (photoError != null) {
        // a operadora foi salva; só a foto falhou
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Operadora salva, mas a foto não foi enviada: $photoError')),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSnack(context, e.message, error: true);
    }
  }

  Widget _photo() {
    final existingUrl = widget.existing?.photoUrl;
    Widget content;
    if (_newPhotoBytes != null) {
      content = Image.memory(_newPhotoBytes!, fit: BoxFit.cover);
    } else if (existingUrl != null && !_removePhoto) {
      content = RemoteImage(url: existingUrl, cacheKey: widget.existing?.photoId);
    } else {
      content = Container(
        color: context.softFill,
        child: const Icon(Icons.storefront_outlined, size: 40, color: DiverrTheme.primary),
      );
    }
    final hasPhoto = _newPhotoBytes != null || (existingUrl != null && !_removePhoto);

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(width: 104, height: 104, child: content),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(hasPhoto ? 'Trocar foto' : 'Adicionar foto'),
              ),
              if (hasPhoto)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _newPhoto = null;
                    _newPhotoBytes = null;
                    _removePhoto = true;
                  }),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Remover foto'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Editar operadora' : 'Nova operadora')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            _photo(),
            const SizedBox(height: 22),
            TextFormField(
              controller: _nome,
              maxLength: 150,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome da operadora', prefixIcon: Icon(Icons.storefront_outlined)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SectionTitle('Onde atua'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in _siteIds)
                  InputChip(
                    label: Text(_siteNames[id] ?? 'Local'),
                    onDeleted: () => setState(() => _siteIds = {..._siteIds}..remove(id)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickSites,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(_siteIds.isEmpty ? 'Escolher locais' : 'Alterar locais (${_siteIds.length})'),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Operadora ativa', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Desativada, ela some para os usuários'),
                value: _ativo,
                onChanged: (v) => setState(() => _ativo = v),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: LoadingButton(
            loading: _saving,
            onPressed: _save,
            label: _isEdit ? 'Salvar alterações' : 'Cadastrar operadora',
            icon: Icons.check,
          ),
        ),
      ),
    );
  }
}
