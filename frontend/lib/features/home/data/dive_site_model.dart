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

const Map<String, String> kNivelLabels = {
  'INICIANTE': 'Iniciante',
  'INTERMEDIARIO': 'Intermediário',
  'AVANCADO': 'Avançado',
  'TECNICO': 'Técnico',
};

String nivelLabel(String? nivel) =>
    nivel == null ? '—' : (kNivelLabels[nivel] ?? nivel);

/// Informações avançadas do local (somente Premium/ADMIN recebem do servidor).
class SiteExtended {
  final String? melhorEpoca;
  final String? visibilidadeTipica;
  final String? temperaturaAgua;
  final String? correnteTipica;
  final String? certificacaoMinima;
  final String? faunaFlora;
  final String? comoChegar;
  final String? infraestrutura;
  final String? dicas;
  final String? avisosSeguranca;

  const SiteExtended({
    this.melhorEpoca,
    this.visibilidadeTipica,
    this.temperaturaAgua,
    this.correnteTipica,
    this.certificacaoMinima,
    this.faunaFlora,
    this.comoChegar,
    this.infraestrutura,
    this.dicas,
    this.avisosSeguranca,
  });

  factory SiteExtended.fromJson(Map<String, dynamic> j) => SiteExtended(
        melhorEpoca: j['melhorEpoca'] as String?,
        visibilidadeTipica: j['visibilidadeTipica'] as String?,
        temperaturaAgua: j['temperaturaAgua'] as String?,
        correnteTipica: j['correnteTipica'] as String?,
        certificacaoMinima: j['certificacaoMinima'] as String?,
        faunaFlora: j['faunaFlora'] as String?,
        comoChegar: j['comoChegar'] as String?,
        infraestrutura: j['infraestrutura'] as String?,
        dicas: j['dicas'] as String?,
        avisosSeguranca: j['avisosSeguranca'] as String?,
      );

  static bool _has(String? v) => v != null && v.trim().isNotEmpty;

  bool get isEmpty =>
      !_has(melhorEpoca) &&
      !_has(visibilidadeTipica) &&
      !_has(temperaturaAgua) &&
      !_has(correnteTipica) &&
      !_has(certificacaoMinima) &&
      !_has(faunaFlora) &&
      !_has(comoChegar) &&
      !_has(infraestrutura) &&
      !_has(dicas) &&
      !_has(avisosSeguranca);
}

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
  final String? nivel;
  final bool ativo;
  final List<ImageRef> images;

  /// Total de fotos que existem (o servidor limita as visíveis no plano Free).
  final int totalImages;
  final double? ratingAverage;
  final int ratingCount;
  final SiteExtended? extended;

  /// true quando existe conteúdo avançado que o plano atual não enxerga.
  final bool extendedLocked;

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
    this.nivel,
    this.ativo = true,
    this.images = const [],
    this.totalImages = 0,
    this.ratingAverage,
    this.ratingCount = 0,
    this.extended,
    this.extendedLocked = false,
  });

  int get hiddenImages => totalImages > images.length ? totalImages - images.length : 0;

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
      nivel: json['nivel']?.toString(),
      ativo: json['ativo'] as bool? ?? true,
      images: ImageRef.listFrom(json['images']),
      totalImages: (json['totalImages'] as num?)?.toInt() ??
          ImageRef.listFrom(json['images']).length,
      ratingAverage: (json['ratingAverage'] as num?)?.toDouble(),
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      extended: json['extended'] is Map
          ? SiteExtended.fromJson(Map<String, dynamic>.from(json['extended'] as Map))
          : null,
      extendedLocked: json['extendedLocked'] as bool? ?? false,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
