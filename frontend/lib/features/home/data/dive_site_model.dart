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
  });

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

      profundidadeMaxima:
      json['profundidadeMaxima'] == null
          ? null
          : _toDouble(json['profundidadeMaxima']),

      tipo: json['tipo']?.toString(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0.0;
  }
}