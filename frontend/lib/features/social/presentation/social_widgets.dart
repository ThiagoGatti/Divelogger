import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/events.dart';
import '../../../core/format.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ui/widgets.dart';
import '../data/social_api.dart';
import '../data/social_models.dart';

/// Foto de perfil (quando existe) ou círculo com as iniciais.
class UserAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final String? photoUrl;
  final String? photoId;
  const UserAvatar({super.key, required this.name, this.radius = 20, this.photoUrl, this.photoId});

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null) {
      return ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: RemoteImage(
            url: photoUrl,
            cacheKey: photoId,
            placeholderIcon: Icons.person,
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: DiverrTheme.ocean.withOpacity(.4),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: DiverrTheme.primary,
          fontSize: radius * .75,
        ),
      ),
    );
  }
}

/// Linha de usuário (busca, seguidores, seguindo, amigos).
class UserTile extends StatelessWidget {
  final UserSummary user;
  final VoidCallback onTap;
  final Widget? trailing;
  const UserTile({super.key, required this.user, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
        leading: UserAvatar(name: user.nome, photoUrl: user.photoUrl, photoId: user.photoId),
        title: Text(user.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (user.username != null) Text('@${user.username}'),
            if (user.friends)
              const InfoChip(icon: Icons.people_alt_outlined, text: 'Amigos', color: DiverrTheme.success)
            else if (user.followsMe)
              const InfoChip(text: 'Segue você', color: DiverrTheme.muted),
          ],
        ),
        trailing: trailing,
      ),
    );
  }
}

/// Seguir / Seguindo / Seguir de volta / Amigos. Seguir é imediato.
class FollowButton extends StatefulWidget {
  final int userId;
  final bool iFollow;
  final bool followsMe;
  final ValueChanged<PublicProfile>? onChanged;

  const FollowButton({
    super.key,
    required this.userId,
    required this.iFollow,
    required this.followsMe,
    this.onChanged,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  final _api = SocialApi();
  late bool _iFollow = widget.iFollow;
  late bool _followsMe = widget.followsMe;
  bool _busy = false;

  @override
  void didUpdateWidget(covariant FollowButton old) {
    super.didUpdateWidget(old);
    if (old.iFollow != widget.iFollow || old.followsMe != widget.followsMe) {
      _iFollow = widget.iFollow;
      _followsMe = widget.followsMe;
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final p = _iFollow ? await _api.unfollow(widget.userId) : await _api.follow(widget.userId);
      if (!mounted) return;
      setState(() {
        _iFollow = p.iFollow;
        _followsMe = p.followsMe;
        _busy = false;
      });
      AppEvents.notifyFollowsChanged();
      widget.onChanged?.call(p);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = _iFollow && _followsMe;
    final label = friends
        ? 'Amigos'
        : _iFollow
            ? 'Seguindo'
            : (_followsMe ? 'Seguir de volta' : 'Seguir');

    const size = Size(0, 40);
    final child = _busy
        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (friends) const Icon(Icons.people_alt_outlined, size: 18),
              if (friends) const SizedBox(width: 6),
              Text(label),
            ],
          );

    if (_iFollow) {
      return OutlinedButton(
        onPressed: _toggle,
        style: OutlinedButton.styleFrom(minimumSize: size, padding: const EdgeInsets.symmetric(horizontal: 16)),
        child: child,
      );
    }
    return FilledButton(
      onPressed: _toggle,
      style: FilledButton.styleFrom(minimumSize: size, padding: const EdgeInsets.symmetric(horizontal: 18)),
      child: child,
    );
  }
}

/// Barra de reações com emoji. Tocar numa reação marca/troca; tocar na sua remove.
class ReactionBar extends StatefulWidget {
  final String logId;
  final SocialSummary summary;
  final ValueChanged<SocialSummary> onChanged;
  const ReactionBar({super.key, required this.logId, required this.summary, required this.onChanged});

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  final _api = SocialApi();
  bool _busy = false;

  Future<void> _tap(String emoji) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final s = widget.summary.myReaction == emoji
          ? await _api.removeReaction(widget.logId)
          : await _api.react(widget.logId, emoji);
      widget.onChanged(s);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final emoji in kReactionEmojis)
          Builder(builder: (context) {
            final count = widget.summary.reactions[emoji] ?? 0;
            final selected = widget.summary.myReaction == emoji;
            return InkWell(
              onTap: () => _tap(emoji),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? DiverrTheme.primary.withOpacity(.12) : context.surfaceColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? DiverrTheme.primary : DiverrTheme.dark.withOpacity(.10),
                    width: selected ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    if (count > 0) ...[
                      const SizedBox(width: 5),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: selected ? DiverrTheme.primary : DiverrTheme.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

/// Reações + comentários de um mergulho (para o dono e para quem pode vê-lo).
class DiveLogSocialSection extends StatefulWidget {
  final String logId;
  const DiveLogSocialSection({super.key, required this.logId});

  @override
  State<DiveLogSocialSection> createState() => _DiveLogSocialSectionState();
}

class _DiveLogSocialSectionState extends State<DiveLogSocialSection> {
  final _api = SocialApi();
  final _text = TextEditingController();

  SocialSummary _summary = const SocialSummary();
  List<CommentModel> _comments = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([_api.summary(widget.logId), _api.comments(widget.logId)]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as SocialSummary;
        _comments = results[1] as List<CommentModel>;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _send() async {
    final texto = _text.text.trim();
    if (texto.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final list = await _api.addComment(widget.logId, texto);
      if (!mounted) return;
      _text.clear();
      FocusScope.of(context).unfocus();
      setState(() {
        _comments = list;
        _summary = SocialSummary(
          reactions: _summary.reactions,
          myReaction: _summary.myReaction,
          commentsCount: list.length,
        );
        _sending = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      showSnack(context, e.message, error: true);
    }
  }

  Future<void> _delete(CommentModel c) async {
    final ok = await confirmDialog(
      context,
      title: 'Apagar comentário?',
      message: 'Este comentário será removido.',
      confirmLabel: 'Apagar',
      destructive: true,
    );
    if (!ok) return;
    try {
      final list = await _api.deleteComment(widget.logId, c.id);
      if (mounted) setState(() => _comments = list);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SkeletonList(count: 1, height: 90);
    if (_error != null) return ErrorState(message: _error!, onRetry: _load);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Reações'),
        ReactionBar(
          logId: widget.logId,
          summary: _summary,
          onChanged: (s) => setState(() => _summary = s),
        ),
        SectionTitle('Comentários (${_comments.length})'),
        for (final c in _comments)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(name: c.autor, radius: 17, photoUrl: c.photoUrl, photoId: c.photoId),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  c.mine ? 'Você' : (c.username != null ? '@${c.username}' : c.autor),
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(timeAgo(c.createdAt), style: const TextStyle(fontSize: 12, color: DiverrTheme.muted)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(c.texto, style: const TextStyle(height: 1.4)),
                        ],
                      ),
                    ),
                    if (c.canDelete)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _delete(c),
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: 'Apagar',
                      ),
                  ],
                ),
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _text,
                maxLength: 1000,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(hintText: 'Escreva um comentário', counterText: ''),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              tooltip: 'Enviar',
            ),
          ],
        ),
      ],
    );
  }
}
