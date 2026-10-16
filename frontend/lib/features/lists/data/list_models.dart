class ListSummary {
  final String id;
  final String nome;
  final String? descricao;
  final bool ranked;
  final String tipo;
  final int itemsCount;
  final String? coverUrl;
  final String? coverImageId;

  const ListSummary({
    required this.id,
    required this.nome,
    this.descricao,
    required this.ranked,
    required this.tipo,
    required this.itemsCount,
    this.coverUrl,
    this.coverImageId,
  });

  factory ListSummary.fromJson(Map<String, dynamic> j) => ListSummary(
        id: j['id']?.toString() ?? '',
        nome: j['nome']?.toString() ?? '',
        descricao: j['descricao'] as String?,
        ranked: j['ranked'] as bool? ?? false,
        tipo: j['tipo']?.toString() ?? 'LISTA',
        itemsCount: (j['itemsCount'] as num?)?.toInt() ?? 0,
        coverUrl: j['coverUrl'] as String?,
        coverImageId: j['coverImageId']?.toString(),
      );
}

class ListItem {
  final String id;
  final int position;
  final String? nota;
  final String siteId;
  final String siteNome;
  final String localizacao;
  final String? tipo;
  final bool ativo;
  final String? coverUrl;
  final String? coverImageId;

  const ListItem({
    required this.id,
    required this.position,
    this.nota,
    required this.siteId,
    required this.siteNome,
    required this.localizacao,
    this.tipo,
    required this.ativo,
    this.coverUrl,
    this.coverImageId,
  });

  factory ListItem.fromJson(Map<String, dynamic> j) => ListItem(
        id: j['id']?.toString() ?? '',
        position: (j['position'] as num?)?.toInt() ?? 0,
        nota: j['nota'] as String?,
        siteId: j['siteId']?.toString() ?? '',
        siteNome: j['siteNome']?.toString() ?? '',
        localizacao: j['localizacao']?.toString() ?? '',
        tipo: j['tipo'] as String?,
        ativo: j['ativo'] as bool? ?? true,
        coverUrl: j['coverUrl'] as String?,
        coverImageId: j['coverImageId']?.toString(),
      );
}

class ListDetail {
  final String id;
  final String nome;
  final String? descricao;
  final bool ranked;
  final String tipo;
  final List<ListItem> items;

  const ListDetail({
    required this.id,
    required this.nome,
    this.descricao,
    required this.ranked,
    required this.tipo,
    required this.items,
  });

  bool get isWishlist => tipo == 'QUERO_MERGULHAR';

  bool containsSite(String siteId) => items.any((i) => i.siteId == siteId);

  factory ListDetail.fromJson(Map<String, dynamic> j) => ListDetail(
        id: j['id']?.toString() ?? '',
        nome: j['nome']?.toString() ?? '',
        descricao: j['descricao'] as String?,
        ranked: j['ranked'] as bool? ?? false,
        tipo: j['tipo']?.toString() ?? 'LISTA',
        items: (j['items'] as List? ?? [])
            .whereType<Map>()
            .map((e) => ListItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
