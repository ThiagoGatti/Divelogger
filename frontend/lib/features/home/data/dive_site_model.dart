import '../../../core/models/image_ref.dart';

const Map<String, String> kTipoLabels = {
  'COSTEIRO': 'Costeiro',
  'NAUFRAGIO': 'Naufrágio',
  'RECIFE': 'Recife',
  'CAVERNA': 'Caverna',
  'PAREDE': 'Parede',
  'PEDREIRA': 'Pedreira',
  'LAGO': 'Lago',
  'RIO': 'Rio',
  'OUTRO': 'Outro',
};

String tipoLabel(String? tipo) =>
    tipo == null ? 'Não informado' : (kTipoLabels[tipo] ?? tipo);

class DiveSiteModel {
  final String id;
  final String nome;
  final String? descricao;
  final String pais;
  final String? estado;
  final String? cidade;
  final double latitude;
  final double longitude;
  final double? profundidadeMaxima;
  final String? tipo;
  final bool ativo;
  final List<ImageRef> images;

  const DiveSiteModel({
    required this.id,
    required this.nome,
    this.descricao,
    required this.pais,
    this.estado,
    this.cidade,
    required this.latitude,
    required this.longitude,
    this.profundidadeMaxima,
    this.tipo,
    this.ativo = true,
    this.images = const [],
  });

  String get localizacao => [cidade, estado, pais]
      .where((v) => v != null && v.isNotEmpty)
      .join(', ');

  String? get coverUrl => images.isEmpty ? null : images.first.url;

  factory DiveSiteModel.fromJson(Map<String, dynamic> json) {
    return DiveSiteModel(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString(),
      pais: json['pais']?.toString() ?? '',
      estado: json['estado']?.toString(),
      cidade: json['cidade']?.toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      profundidadeMaxima: json['profundidadeMaxima'] == null
          ? null
          : _toDouble(json['profundidadeMaxima']),
      tipo: json['tipo']?.toString(),
      ativo: json['ativo'] as bool? ?? true,
      images: ImageRef.listFrom(json['images']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
