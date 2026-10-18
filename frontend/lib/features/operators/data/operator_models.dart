class OperatorSummary {
  final String id;
  final String nome;
  final String? endereco;
  final String? photoUrl;
  final String? photoId;
  final bool ativo;

  const OperatorSummary({
    required this.id,
    required this.nome,
    this.endereco,
    this.photoUrl,
    this.photoId,
    this.ativo = true,
  });

  factory OperatorSummary.fromJson(Map<String, dynamic> j) => OperatorSummary(
        id: j['id']?.toString() ?? '',
        nome: j['nome']?.toString() ?? '',
        endereco: j['endereco'] as String?,
        photoUrl: j['photoUrl'] as String?,
        photoId: j['photoId']?.toString(),
        ativo: j['ativo'] as bool? ?? true,
      );

  static List<OperatorSummary> listFrom(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => OperatorSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class SiteRef {
  final String id;
  final String nome;
  final String localizacao;
  final bool ativo;

  const SiteRef({required this.id, required this.nome, required this.localizacao, required this.ativo});

  factory SiteRef.fromJson(Map<String, dynamic> j) => SiteRef(
        id: j['id']?.toString() ?? '',
        nome: j['nome']?.toString() ?? '',
        localizacao: j['localizacao']?.toString() ?? '',
        ativo: j['ativo'] as bool? ?? true,
      );
}

class OperatorDetail {
  final String id;
  final String nome;
  final String? endereco;
  final String? photoUrl;
  final String? photoId;
  final bool ativo;
  final List<SiteRef> sites;

  const OperatorDetail({
    required this.id,
    required this.nome,
    this.endereco,
    this.photoUrl,
    this.photoId,
    required this.ativo,
    required this.sites,
  });

  factory OperatorDetail.fromJson(Map<String, dynamic> j) => OperatorDetail(
        id: j['id']?.toString() ?? '',
        nome: j['nome']?.toString() ?? '',
        endereco: j['endereco'] as String?,
        photoUrl: j['photoUrl'] as String?,
        photoId: j['photoId']?.toString(),
        ativo: j['ativo'] as bool? ?? true,
        sites: (j['sites'] as List? ?? [])
            .whereType<Map>()
            .map((e) => SiteRef.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
