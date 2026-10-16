class ReviewModel {
  final String id;
  final int userId;
  final String autor;
  final String? username;
  final int rating;
  final String? texto;
  final DateTime createdAt;
  final bool mine;

  const ReviewModel({
    required this.id,
    required this.userId,
    required this.autor,
    this.username,
    required this.rating,
    this.texto,
    required this.createdAt,
    required this.mine,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> j) => ReviewModel(
        id: j['id']?.toString() ?? '',
        userId: (j['userId'] as num?)?.toInt() ?? 0,
        autor: j['autor']?.toString() ?? 'Mergulhador',
        username: j['username'] as String?,
        rating: (j['rating'] as num?)?.toInt() ?? 0,
        texto: j['texto'] as String?,
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
        mine: j['mine'] as bool? ?? false,
      );
}

class ReviewsResult {
  final double? average;
  final int count;
  final ReviewModel? mine;
  final List<ReviewModel> items;

  const ReviewsResult({this.average, this.count = 0, this.mine, this.items = const []});

  factory ReviewsResult.fromJson(Map<String, dynamic> j) => ReviewsResult(
        average: (j['average'] as num?)?.toDouble(),
        count: (j['count'] as num?)?.toInt() ?? 0,
        mine: j['mine'] is Map
            ? ReviewModel.fromJson(Map<String, dynamic>.from(j['mine'] as Map))
            : null,
        items: (j['items'] as List? ?? [])
            .whereType<Map>()
            .map((e) => ReviewModel.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
