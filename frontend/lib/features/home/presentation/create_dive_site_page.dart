import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/theme.dart';
import '../../../core/session/session.dart';
import '../data/dive_sites_api.dart';

class CreateDiveSitePage extends StatefulWidget {
  const CreateDiveSitePage({super.key});

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
  bool _gettingLocation = false;

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

    super.dispose();
  }


  Future<void> _getCurrentLocation() async {
    if (_gettingLocation) {
      return;
    }

    setState(() {
      _gettingLocation = true;
    });

    try {


      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        _showError(
          'A localização do celular está desligada. '
              'Ative o GPS/localização e tente novamente.',
        );

        return;
      }



      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
        await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          if (!mounted) return;

          _showError(
            'A permissão para acessar sua localização foi negada.',
          );

          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        _showError(
          'A permissão de localização foi bloqueada permanentemente. '
              'Ative a localização nas configurações do aplicativo.',
        );

        return;
      }

      debugPrint(
        'PERMISSÃO DE LOCALIZAÇÃO: $permission',
      );

      // ============================================================
      // 3. PRIMEIRO TENTA UMA LOCALIZAÇÃO JÁ CONHECIDA
      // ============================================================

      Position? position =
      await Geolocator.getLastKnownPosition();

      if (position != null) {
        debugPrint(
          'Usando última localização conhecida:',
        );

        debugPrint(
          'Latitude: ${position.latitude}',
        );

        debugPrint(
          'Longitude: ${position.longitude}',
        );

        if (!mounted) return;

        setState(() {
          _latitudeController.text =
              position!.latitude.toStringAsFixed(6);

          _longitudeController.text =
              position.longitude.toStringAsFixed(6);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Localização obtida com sucesso!',
            ),
          ),
        );

        return;
      }
      debugPrint(
        'Nenhuma localização anterior encontrada.',
      );

      debugPrint(
        'Solicitando localização atual...',
      );

      position =
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
            'O GPS demorou muito para responder.',
          );
        },
      );

      // ============================================================
      // 5. RECEBEU A LOCALIZAÇÃO
      // ============================================================

      debugPrint(
        'LOCALIZAÇÃO RECEBIDA!',
      );

      debugPrint(
        'Latitude: ${position.latitude}',
      );

      debugPrint(
        'Longitude: ${position.longitude}',
      );

      if (!mounted) return;

      setState(() {
        _latitudeController.text =
            position!.latitude.toStringAsFixed(6);

        _longitudeController.text =
            position.longitude.toStringAsFixed(6);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Localização obtida com sucesso!',
          ),
        ),
      );
    } on LocationServiceDisabledException {
      if (!mounted) return;

      _showError(
        'O serviço de localização está desativado.',
      );
    } on PermissionDeniedException {
      if (!mounted) return;

      _showError(
        'Permissão de localização negada.',
      );
    } catch (e) {
      debugPrint(
        'ERRO AO OBTER LOCALIZAÇÃO:',
      );

      debugPrint(
        e.toString(),
      );

      if (!mounted) return;

      _showError(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _gettingLocation = false;
        });
      }
    }
  }

  // ============================================================
  // CRIA O DIVE SITE
  // ============================================================

  Future<void> _createDiveSite() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = AppSession.instance.currentUser;

    if (user == null) {
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
      final site = await _api.create(
        nome: _nomeController.text.trim(),
        descricao:
        _descricaoController.text.trim().isEmpty
            ? null
            : _descricaoController.text.trim(),
        pais: _paisController.text.trim(),
        estado:
        _estadoController.text.trim().isEmpty
            ? null
            : _estadoController.text.trim(),
        cidade:
        _cidadeController.text.trim().isEmpty
            ? null
            : _cidadeController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        profundidadeMaxima: profundidade,
        tipo: _tipo,
        createdBy: user.id,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, site);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Dive Site criado com sucesso!',
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
        title: const Text(
          'Novo Dive Site',
          style: TextStyle(
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

            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _gettingLocation
                    ? null
                    : _getCurrentLocation,
                icon: _gettingLocation
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2.5,
                  ),
                )
                    : const Icon(
                  Icons.my_location,
                ),
                label: Text(
                  _gettingLocation
                      ? 'Obtendo localização...'
                      : 'Usar minha localização atual',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                  DiverrTheme.primary,
                  side: const BorderSide(
                    color: DiverrTheme.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                ),
              ),
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
                    : const Text(
                  'Criar Dive Site',
                  style: TextStyle(
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