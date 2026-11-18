import '../../dive_logs/data/dive_log_model.dart';

/// Emojis de reação aceitos pelo servidor (mesma lista do backend).
const List<String> kReactionEmojis = ['🤿', '🌊', '🐠', '🔥', '👏', '❤️'];

class UserSummary {
  final int id;
  final String nome;
  final String? username;
  final String? photoUrl;
  final String? photoId;
  final bool iFollow;
  final bool followsMe;
  final bool friends;

  const UserSummary({
    required this.id,
    required this.nome,
    this.username,
    this.photoUrl,
    this.photoId,
    required this.iFollow,
    required this.followsMe,
    required this.friends,
  });

  factory UserSummary.fromJson(Map<String, dynamic> j) => UserSummary(
        id: (j['id'] as num).toInt(),
        nome: j['nome']?.toString() ?? '',
        username: j['username'] as String?,
        photoUrl: j['photoUrl'] as String?,
        photoId: j['photoId']?.toString(),
        iFollow: j['iFollow'] as bool? ?? false,
        followsMe: j['followsMe'] as bool? ?? false,
        friends: j['friends'] as bool? ?? false,
      );
}

class PublicProfile {
  final int id;
  final String nomeCompleto;
  final String? username;
  final String? bio;
  final String? photoUrl;
  final String? photoId;
  final bool self;
  final int followers;
  final int following;
  final int friends;
  final bool iFollow;
  final bool followsMe;
  final bool isFriend;
  final String diveVisibility;
  final bool canViewDives;
  final int? divesCount;
  final int? sitesCount;

  const PublicProfile({
    required this.id,
    required this.nomeCompleto,
    this.username,
    this.bio,
    this.photoUrl,
    this.photoId,
    required this.self,
    required this.followers,
    required this.following,
    required this.friends,
    required this.iFollow,
    required this.followsMe,
    required this.isFriend,
    required this.diveVisibility,
    required this.canViewDives,
    this.divesCount,
    this.sitesCount,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> j) => PublicProfile(
        id: (j['id'] as num).toInt(),
        nomeCompleto: j['nomeCompleto']?.toString() ?? '',
        username: j['username'] as String?,
        bio: j['bio'] as String?,
        photoUrl: j['photoUrl'] as String?,
        photoId: j['photoId']?.toString(),
        self: j['self'] as bool? ?? false,
        followers: (j['followers'] as num?)?.toInt() ?? 0,
        following: (j['following'] as num?)?.toInt() ?? 0,
        friends: (j['friends'] as num?)?.toInt() ?? 0,
        iFollow: j['iFollow'] as bool? ?? false,
        followsMe: j['followsMe'] as bool? ?? false,
        isFriend: j['isFriend'] as bool? ?? false,
        diveVisibility: j['diveVisibility']?.toString() ?? 'FOLLOWERS',
        canViewDives: j['canViewDives'] as bool? ?? false,
        divesCount: (j['divesCount'] as num?)?.toInt(),
        sitesCount: (j['sitesCount'] as num?)?.toInt(),
      );
}

class SocialSummary {
  final Map<String, int> reactions;
  final String? myReaction;
  final int commentsCount;

  const SocialSummary({
    this.reactions = const {},
    this.myReaction,
    this.commentsCount = 0,
  });

  int get totalReactions => reactions.values.fold(0, (a, b) => a + b);

  factory SocialSummary.fromJson(Map<String, dynamic> j) {
    final raw = j['reactions'];
    final map = <String, int>{};
    if (raw is Map) {
      raw.forEach((k, v) => map[k.toString()] = (v as num).toInt());
    }
    return SocialSummary(
      reactions: map,
      myReaction: j['myReaction'] as String?,
      commentsCount: (j['commentsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class CommentModel {
  final String id;
  final int userId;
  final String autor;
  final String? username;
  final String? photoUrl;
  final String? photoId;
  final String texto;
  final DateTime createdAt;
  final bool mine;
  final bool canDelete;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.autor,
    this.username,
    this.photoUrl,
    this.photoId,
    required this.texto,
    required this.createdAt,
    required this.mine,
    required this.canDelete,
  });

  factory CommentModel.fromJson(Map<String, dynamic> j) => CommentModel(
        id: j['id']?.toString() ?? '',
        userId: (j['userId'] as num?)?.toInt() ?? 0,
        autor: j['autor']?.toString() ?? 'Mergulhador',
        username: j['username'] as String?,
        photoUrl: j['photoUrl'] as String?,
        photoId: j['photoId']?.toString(),
        texto: j['texto']?.toString() ?? '',
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
        mine: j['mine'] as bool? ?? false,
        canDelete: j['canDelete'] as bool? ?? false,
      );
}

class FeedItem {
  final DiveLogModel dive;
  final SocialSummary social;
  const FeedItem({required this.dive, required this.social});

  factory FeedItem.fromJson(Map<String, dynamic> j) => FeedItem(
        dive: DiveLogModel.fromJson(Map<String, dynamic>.from(j['dive'] as Map)),
        social: j['social'] is Map
            ? SocialSummary.fromJson(Map<String, dynamic>.from(j['social'] as Map))
            : const SocialSummary(),
      );
}

class FeedPage {
  final List<FeedItem> items;
  final bool hasMore;
  final int page;
  const FeedPage({required this.items, required this.hasMore, required this.page});

  factory FeedPage.fromJson(Map<String, dynamic> j) => FeedPage(
        items: (j['items'] as List? ?? [])
            .whereType<Map>()
            .map((e) => FeedItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        hasMore: j['hasMore'] as bool? ?? false,
        page: (j['page'] as num?)?.toInt() ?? 0,
      );
}
