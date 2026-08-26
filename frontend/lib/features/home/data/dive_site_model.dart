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

  const DiveSiteModel({required this.id, required this.nome, this.descricao, required this.pais, this.estado, this.cidade, required this.latitude, required this.longitude, this.profundidadeMaxima, this.tipo});

  factory DiveSiteModel.fromJson(Map<String, dynamic> json) => DiveSiteModel(
    id: json['id'].toString(), nome: json['nome'] ?? '', descricao: json['descricao'], pais: json['pais'] ?? '', estado: json['estado'], cidade: json['cidade'], latitude: (json['latitude'] as num).toDouble(), longitude: (json['longitude'] as num).toDouble(), profundidadeMaxima: (json['profundidadeMaxima'] as num?)?.toDouble(), tipo: json['tipo'],
  );
}
