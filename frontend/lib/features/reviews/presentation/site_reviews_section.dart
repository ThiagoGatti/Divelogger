import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/ui/widgets.dart';
import '../data/review_models.dart';
import '../data/reviews_api.dart';

/// Avaliações e comentários de um Dive Site: média, lista e "Avaliar este local".
class SiteReviewsSection extends StatefulWidget {
  final String siteId;
  final bool canReview;
  const SiteReviewsSection({super.key, required this.siteId, this.canReview = true});

  @override
  State<SiteReviewsSection> createState() => _SiteReviewsSectionState();
}

class _SiteReviewsSectionState extends State<SiteReviewsSection> {
  final _api = ReviewsApi();
  ReviewsResult? _data;
  bool _loading = true;
  String? _error;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _api.list(widget.siteId);
      if (!mounted) return;
      setState(() {
        _data = d;
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

  Future<void> _write() async {
    final mine = _data?.mine;
    final result = await showModalBottomSheet<_ReviewInput>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _ReviewSheet(initialRating: mine?.rating ?? 0, initialText: mine?.texto ?? ''),
      ),
    );
    if (result == null) return;

    try {
      final updated = await _api.saveMine(widget.siteId, result.rating, result.texto);
      if (!mounted) return;
      setState(() => _data = updated);
      showSnack(context, 'Avaliação salva. Obrigado!');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _remove(ReviewModel r) async {
    final ok = await confirmDialog(
      context,
      title: 'Remover avaliação?',
      message: r.mine ? 'Sua avaliação será apagada.' : 'A avaliação de ${r.autor} será apagada.',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!ok) return;
    try {
      final updated = r.mine
          ? await _api.deleteMine(widget.siteId)
          : await _api.deleteAny(widget.siteId, r.id);
      if (mounted) setState(() => _data = updated);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final isAdmin = AppSession.instance.isAdmin;

    if (_loading) return const SkeletonList(count: 1, height: 90);
    if (_error != null) return ErrorState(message: _error!, onRetry: _load);

    final items = data!.items;
    final visible = _showAll ? items : items.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DiverrTheme.radius),
            boxShadow: DiverrTheme.softShadow,
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    data.average == null ? '—' : data.average!.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, height: 1),
                  ),
                  const SizedBox(height: 4),
                  RatingStars(value: (data.average ?? 0).round(), size: 16),
                  const SizedBox(height: 4),
                  Text(
                    '${data.count} ${data.count == 1 ? 'avaliação' : 'avaliações'}',
                    style: const TextStyle(color: DiverrTheme.muted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: widget.canReview
                    ? FilledButton.icon(
                        onPressed: _write,
                        icon: const Icon(Icons.rate_review_outlined),
                        label: Text(data.mine == null ? 'Avaliar este local' : 'Editar minha avaliação'),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Seja o primeiro a avaliar este local.', style: TextStyle(color: DiverrTheme.muted)),
          )
        else ...[
          const SizedBox(height: 12),
          for (final r in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: DiverrTheme.ocean.withOpacity(.35),
                            child: Text(initialsOf(r.autor), style: const TextStyle(fontWeight: FontWeight.w900, color: DiverrTheme.primary, fontSize: 13)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.mine ? 'Você' : (r.username != null ? '@${r.username}' : r.autor),
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                Text(formatDate(r.createdAt), style: const TextStyle(color: DiverrTheme.muted, fontSize: 12)),
                              ],
                            ),
                          ),
                          RatingStars(value: r.rating, size: 16),
                          if (r.mine || isAdmin)
                            IconButton(
                              onPressed: () => _remove(r),
                              icon: const Icon(Icons.delete_outline, size: 20),
                              tooltip: 'Remover',
                            ),
                        ],
                      ),
                      if (r.texto != null && r.texto!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(r.texto!, style: const TextStyle(height: 1.45)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          if (items.length > 3)
            TextButton(
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Text(_showAll ? 'Mostrar menos' : 'Ver todas as ${items.length} avaliações'),
            ),
        ],
      ],
    );
  }
}

class _ReviewInput {
  final int rating;
  final String? texto;
  _ReviewInput(this.rating, this.texto);
}

class _ReviewSheet extends StatefulWidget {
  final int initialRating;
  final String initialText;
  const _ReviewSheet({required this.initialRating, required this.initialText});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late int _rating = widget.initialRating;
  late final TextEditingController _text = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Avaliar este local', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            RatingStars(value: _rating, size: 40, onChanged: (v) => setState(() => _rating = v)),
            const SizedBox(height: 14),
            TextField(
              controller: _text,
              maxLines: 4,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Comentário (opcional)',
                hintText: 'Como foi mergulhar aqui? Dicas, condições, o que viu...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _rating == 0
                  ? null
                  : () => Navigator.pop(
                        context,
                        _ReviewInput(_rating, _text.text.trim().isEmpty ? null : _text.text.trim()),
                      ),
              child: const Text('Publicar avaliação'),
            ),
          ],
        ),
      ),
    );
  }
}
