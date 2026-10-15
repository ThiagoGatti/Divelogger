/// Imagem devolvida pela API: id (usado como chave de cache) + URL temporária de leitura.
class ImageRef {
  final String id;
  final String? url;

  const ImageRef({required this.id, this.url});

  factory ImageRef.fromJson(Map<String, dynamic> json) => ImageRef(
        id: json['id']?.toString() ?? '',
        url: json['url']?.toString(),
      );

  static List<ImageRef> listFrom(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => ImageRef.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
