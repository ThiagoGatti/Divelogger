import '../../../core/models/image_ref.dart';

const Map<String, String> kCorrenteLabels = {
  'NENHUMA': 'Nenhuma',
  'FRACA': 'Fraca',
  'MODERADA': 'Moderada',
  'FORTE': 'Forte',
};

const Map<String, String> kAguaLabels = {
  'SALGADA': 'Salgada',
  'DOCE': 'Doce',
};

const Map<String, String> kEntradaLabels = {
  'PRAIA': 'Praia',
  'BARCO': 'Barco',
  'COSTA': 'Costa',
  'PIER': 'Píer',
  'PISCINA': 'Piscina',
  'OUTRO': 'Outro',
};

const Map<String, String> kGasLabels = {
  'AR': 'Ar',
  'NITROX': 'Nitrox',
  'TRIMIX': 'Trimix',
  'OUTRO': 'Outro',
};

String labelOf(Map<String, String> labels, String? key) =>
    key == null ? '—' : (labels[key] ?? key);

class DiveLogModel {
  final String id;
  final String diveSiteId;
  final String diveSiteNome;
  final DateTime dataHora;
  final int? duracaoMinutos;
  final double? profundidadeMaxima;
  final double? profundidadeMedia;
  final double? visibilidade;
  final double? temperaturaAgua;
  final String? corrente;
  final String? tipoAgua;
  final String? tipoEntrada;
  final String? tipoGas;
  final int? pressaoInicial;
  final int? pressaoFinal;
  final int? avaliacao;
  final String? observacoes;
  final List<ImageRef> imagens;

  const DiveLogModel({
    required this.id,
    required this.diveSiteId,
    required this.diveSiteNome,
    required this.dataHora,
    this.duracaoMinutos,
    this.profundidadeMaxima,
    this.profundidadeMedia,
    this.visibilidade,
    this.temperaturaAgua,
    this.corrente,
    this.tipoAgua,
    this.tipoEntrada,
    this.tipoGas,
    this.pressaoInicial,
    this.pressaoFinal,
    this.avaliacao,
    this.observacoes,
    this.imagens = const [],
  });

  int? get consumoBar => (pressaoInicial != null && pressaoFinal != null)
      ? pressaoInicial! - pressaoFinal!
      : null;

  String? get coverUrl => imagens.isEmpty ? null : imagens.first.url;

  factory DiveLogModel.fromJson(Map<String, dynamic> json) {
    double? d(dynamic v) => v == null ? null : (v as num).toDouble();
    int? i(dynamic v) => v == null ? null : (v as num).toInt();

    return DiveLogModel(
      id: json['id']?.toString() ?? '',
      diveSiteId: json['diveSiteId']?.toString() ?? '',
      diveSiteNome: json['diveSiteNome']?.toString() ?? '',
      dataHora: DateTime.tryParse(json['dataHora']?.toString() ?? '') ?? DateTime.now(),
      duracaoMinutos: i(json['duracaoMinutos']),
      profundidadeMaxima: d(json['profundidadeMaxima']),
      profundidadeMedia: d(json['profundidadeMedia']),
      visibilidade: d(json['visibilidade']),
      temperaturaAgua: d(json['temperaturaAgua']),
      corrente: json['corrente']?.toString(),
      tipoAgua: json['tipoAgua']?.toString(),
      tipoEntrada: json['tipoEntrada']?.toString(),
      tipoGas: json['tipoGas']?.toString(),
      pressaoInicial: i(json['pressaoInicial']),
      pressaoFinal: i(json['pressaoFinal']),
      avaliacao: i(json['avaliacao']),
      observacoes: json['observacoes']?.toString(),
      imagens: ImageRef.listFrom(json['imagens']),
    );
  }
}
