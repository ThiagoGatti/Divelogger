import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme.dart';
import '../../../core/session/session.dart';
import '../../../core/maps/coordinate_parser.dart';
import '../data/dive_site_model.dart';
import 'location_picker_page.dart';
import '../data/dive_sites_api.dart';

class CreateDiveSitePage extends StatefulWidget {
  /// Quando informado, a tela funciona em modo EDIÇÃO (somente ADMIN).
  final DiveSiteModel? site;

  const CreateDiveSitePage({super.key, this.site});

  @override
  State<CreateDiveSitePage> createState() => _CreateDiveSitePageState();
}

class _CreateDiveSitePageState extends State<CreateDiveSitePage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _paisController = TextEditingController(text: 'Brasil');
  final _estadoController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _profundidadeController = TextEditingController();

  final DiveSitesApi _api = DiveSitesApi();

  String? _tipo;
  bool _saving = false;

  String? _nivel;

  /// Informações avançadas (visíveis só para Premium/ADMIN): chave do backend, rótulo, dica, linhas.
  static const List<(String, String, String, int)> _extFields = [
    ('melhorEpoca', 'Melhor época', 'Ex.: outubro a março', 1),
    ('visibilidadeTipica', 'Visibilidade típica', 'Ex.: 10 a 25 m', 1),
    ('temperaturaAgua', 'Temperatura da água', 'Ex.: 22 a 28 °C', 1),
    ('correnteTipica', 'Corrente típica', 'Ex.: fraca a moderada', 1),
    ('certificacaoMinima', 'Certificação mínima', 'Ex.: Open Water', 1),
    ('faunaFlora', 'Fauna e flora', 'O que normalmente se vê no local', 3),
    ('comoChegar', 'Como chegar', 'Acesso, barco, trilha, estacionamento...', 3),
    ('dicas', 'Dicas do local', 'Dicas para quem vai mergulhar aqui', 3),
    ('avisosSeguranca', 'Avisos de segurança', 'Perigos e cuidados importantes', 3),
  ];

  final Map<String, TextEditingController> _ext = {
    for (final f in _extFields) f.$1: TextEditingController(),
  };

  static String? _extValue(SiteExtended e, String key) {
    switch (key) {
      case 'melhorEpoca':
        return e.melhorEpoca;
      case 'visibilidadeTipica':
        return e.visibilidadeTipica;
      case 'temperaturaAgua':
        return e.temperaturaAgua;
      case 'correnteTipica':
        return e.correnteTipica;
      case 'certificacaoMinima':
        return e.certificacaoMinima;
      case 'faunaFlora':
        return e.faunaFlora;
      case 'comoChegar':
        return e.comoChegar;
      case 'infraestrutura':
        return e.infraestrutura;
      case 'dicas':
        return e.dicas;
      case 'avisosSeguranca':
        return e.avisosSeguranca;
    }
    return null;
  }


  final List<Map<String, String>> _tipos = const [
    {
      'value': 'COSTEIRO',
      'label': 'Costeiro',
    },
    {
      'value': 'NAUFRAGIO',
      'label': 'Naufrágio',
    },
    {
      'value': 'RECIFE',
      'label': 'Recife',
    },
    {
      'value': 'CAVERNA',
      'label': 'Caverna',
    },
    {
      'value': 'PAREDE',
      'label': 'Parede',
    },
    {
      'value': 'PEDREIRA',
      'label': 'Pedreira',
    },
    {
      'value': 'LAGO',
      'label': 'Lago',
    },
    {
      'value': 'RIO',
      'label': 'Rio',
    },
    {
      'value': 'OUTRO',
      'label': 'Outro',
    },
  ];

  bool get _isEdit => widget.site != null;

  @override
  void initState() {
    super.initState();
    final s = widget.site;
    if (s != null) {
      _nomeController.text = s.nome;
      _descricaoController.text = s.descricao ?? '';
      _paisController.text = s.pais;
      _estadoController.text = s.estado ?? '';
      _cidadeController.text = s.cidade ?? '';
      _latitudeController.text = s.latitude.toString();
      _longitudeController.text = s.longitude.toString();
      _profundidadeController.text = s.profundidadeMaxima == null
          ? ''
          : (s.profundidadeMaxima! == s.profundidadeMaxima!.truncateToDouble()
              ? s.profundidadeMaxima!.toStringAsFixed(0)
              : s.profundidadeMaxima.toString());
      _tipo = s.tipo;
      _nivel = s.nivel;
      final e = s.extended;
      if (e != null) {
        for (final f in _extFields) {
          _ext[f.$1]!.text = _extValue(e, f.$1) ?? '';
        }
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _paisController.dispose();
    _estadoController.dispose();
    _cidadeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _profundidadeController.dispose();
    for (final c in _ext.values) {
      c.dispose();
    }

    super.dispose();
  }


  /// Abre o mapa (satélite) com uma cruz no centro: o ponto sob a cruz é o que vai para os campos.
  Future<void> _pickOnMap() async {
    final current = CoordinateParser.tryPair(_latitudeController.text, _longitudeController.text);
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => LocationPickerPage(initial: current)),
    );
    if (result == null || !mounted) return;
    setState(() {
      _latitudeController.text = result.latitude.toStringAsFixed(6);
      _longitudeController.text = result.longitude.toStringAsFixed(6);
    });
  }

  /// Se o admin colar "lat, lng" (de outro app) no campo de latitude, separa nos dois campos.
  void _splitIfPair(String value) {
    final pair = CoordinateParser.parsePair(value);
    if (pair == null) return;
    _latitudeController.text = pair.lat.toStringAsFixed(6);
    _longitudeController.text = pair.lng.toStringAsFixed(6);
  }

  // ============================================================

  Future<void> _createDiveSite() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!AppSession.instance.isLoggedIn) {
      _showError(
        'Usuário não encontrado. Faça login novamente.',
      );
      return;
    }

    final latitude = double.tryParse(
      _latitudeController.text.trim().replaceAll(',', '.'),
    );

    final longitude = double.tryParse(
      _longitudeController.text.trim().replaceAll(',', '.'),
    );

    final profundidade =
    _profundidadeController.text.trim().isEmpty
        ? null
        : double.tryParse(
      _profundidadeController.text
          .trim()
          .replaceAll(',', '.'),
    );

    if (latitude == null ||
        latitude < -90 ||
        latitude > 90) {
      _showError(
        'Latitude inválida. Use um valor entre -90 e 90.',
      );
      return;
    }

    if (longitude == null ||
        longitude < -180 ||
        longitude > 180) {
      _showError(
        'Longitude inválida. Use um valor entre -180 e 180.',
      );
      return;
    }

    if (_profundidadeController.text.trim().isNotEmpty &&
        profundidade == null) {
      _showError(
        'Profundidade máxima inválida.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      String? clean(TextEditingController c) {
        final t = c.text.trim();
        return t.isEmpty ? null : t;
      }

      final input = DiveSiteInput(
        nome: _nomeController.text.trim(),
        descricao: clean(_descricaoController),
        pais: _paisController.text.trim(),
        estado: clean(_estadoController),
        cidade: clean(_cidadeController),
        latitude: latitude,
        longitude: longitude,
        profundidadeMaxima: profundidade,
        tipo: _tipo,
        nivel: _nivel,
        extended: {for (final f in _extFields) f.$1: clean(_ext[f.$1]!)},
      );

      final site = _isEdit
          ? await _api.update(widget.site!.id, input)
          : await _api.create(input);


      if (!mounted) {
        return;
      }

      Navigator.pop(context, site);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Dive Site atualizado!'
                : 'Dive Site criado com sucesso!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showError(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // ============================================================
  // MENSAGEM DE ERRO
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  // ============================================================
  // DECORAÇÃO DOS CAMPOS
  // ============================================================

  InputDecoration _decoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(
        icon,
        color: DiverrTheme.primary,
      )
          : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: DiverrTheme.primary,
          width: 2,
        ),
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Editar Dive Site' : 'Novo Dive Site',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            40,
          ),
          children: [
            // ==================================================
            // INTRODUÇÃO
            // ==================================================

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DiverrTheme.ocean.withOpacity(.18),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on,
                    color: DiverrTheme.primary,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cadastre um novo ponto de mergulho',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Ajude outros mergulhadores a descobrir '
                              'novos lugares.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // INFORMAÇÕES
            // ==================================================

            const Text(
              'Informações',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _nomeController,
              textInputAction: TextInputAction.next,
              decoration: _decoration(
                label: 'Nome do Dive Site',
                hint: 'Ex.: Ilha Anchieta',
                icon: Icons.place_outlined,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Informe o nome do Dive Site.';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _descricaoController,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: _decoration(
                label: 'Descrição',
                hint:
                'Conte um pouco sobre este local...',
                icon: Icons.description_outlined,
              ),
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _tipo,
              decoration: _decoration(
                label: 'Tipo de Dive Site',
                icon: Icons.category_outlined,
              ),
              items: _tipos
                  .map(
                    (tipo) =>
                    DropdownMenuItem<String>(
                      value: tipo['value'],
                      child: Text(
                        tipo['label']!,
                      ),
                    ),
              )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _tipo = value;
                });
              },
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _nivel,
              decoration: _decoration(
                label: 'Nível de dificuldade',
                icon: Icons.stairs_outlined,
              ),
              items: kNivelLabels.entries
                  .map((e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _nivel = value),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // LOCALIZAÇÃO
            // ==================================================

            const Text(
              'Localização',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _paisController,
              textInputAction: TextInputAction.next,
              decoration: _decoration(
                label: 'País',
                icon: Icons.public,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Informe o país.';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _estadoController,
                    textInputAction:
                    TextInputAction.next,
                    decoration: _decoration(
                      label: 'Estado',
                      hint: 'SP',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cidadeController,
                    textInputAction:
                    TextInputAction.next,
                    decoration: _decoration(
                      label: 'Cidade',
                      hint: 'Ubatuba',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ==================================================
            // LATITUDE E LONGITUDE
            // ==================================================

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
              onChanged: _splitIfPair,
                    keyboardType:
                    const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: _decoration(
                      label: 'Latitude',
                      hint: '-23.5329',
                      icon: Icons.north,
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Obrigatório';
                      }

                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    keyboardType:
                    const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: _decoration(
                      label: 'Longitude',
                      hint: '-45.0796',
                      icon: Icons.east,
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Obrigatório';
                      }

                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ==================================================
            // BOTÃO DE LOCALIZAÇÃO AUTOMÁTICA
            // ==================================================

            OutlinedButton.icon(
              onPressed: _pickOnMap,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Marcar o ponto no mapa (satélite)'),
            ),

            const SizedBox(height: 8),

            Text(
              'Use coordenadas decimais. Ex.: -23.5329, -45.0796',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // CARACTERÍSTICAS
            // ==================================================

            const Text(
              'Características',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller:
              _profundidadeController,
              keyboardType:
              const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _decoration(
                label: 'Profundidade máxima',
                hint: 'Ex.: 30',
                icon: Icons.arrow_downward,
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // INFORMAÇÕES AVANÇADAS (PREMIUM)
            // ==================================================

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Informações avançadas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DiverrTheme.gold.withOpacity(.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'PREMIUM',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF9A6B00),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Só assinantes Premium veem estes campos (e todas as fotos do local). Usuários Free veem o resumo e 2 fotos.',
              style: TextStyle(color: DiverrTheme.muted, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 14),
            for (final f in _extFields) ...[
              TextFormField(
                controller: _ext[f.$1],
                minLines: f.$4,
                maxLines: f.$4 == 1 ? 1 : 6,
                maxLength: f.$4 == 1 ? 200 : 2000,
                decoration: _decoration(label: f.$2, hint: f.$3),
              ),
              const SizedBox(height: 10),
            ],

            const SizedBox(height: 20),

            // ==================================================
            // BOTÃO CRIAR
            // ==================================================

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed:
                _saving ? null : _createDiveSite,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  DiverrTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  _isEdit ? 'Salvar alterações' : 'Criar Dive Site',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}