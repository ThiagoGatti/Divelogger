import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';

// ============================================================
// Feedback
// ============================================================

void showSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? DiverrTheme.danger : (context.isDarkMode ? DiverrTheme.darkSoft : DiverrTheme.dark),
      ),
    );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(
            foregroundColor: destructive ? DiverrTheme.danger : DiverrTheme.primary,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Mostrado quando o plano Free bloqueia algo (também quando o backend responde PLAN_LIMIT).
Future<void> showUpgradeSheet(BuildContext context, {String? message}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: DiverrTheme.gold.withOpacity(.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium, color: DiverrTheme.gold, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Diverr Premium',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            if (message != null) ...[
              const SizedBox(height: 14),
              Text(message, style: const TextStyle(color: DiverrTheme.muted, height: 1.4)),
            ],
            const SizedBox(height: 18),
            const _Benefit(Icons.all_inclusive, 'Mergulhos ilimitados no seu diário'),
            const _Benefit(Icons.photo_library_outlined, 'Até 10 fotos por mergulho'),
            const _Benefit(Icons.insights_outlined, 'Estatísticas avançadas da sua evolução'),
            const _Benefit(Icons.ios_share_outlined, 'Exportação dos seus dados'),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.softFill,
                borderRadius: BorderRadius.circular(DiverrTheme.radiusSmall),
              ),
              child: const Row(
                children: [
                  Icon(Icons.schedule, size: 20, color: DiverrTheme.muted),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'A assinatura direto pelo app será liberada em breve.',
                      style: TextStyle(color: DiverrTheme.muted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendi'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Benefit(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: DiverrTheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

// ============================================================
// Estrutura de página
// ============================================================

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const PageHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(subtitle!, style: const TextStyle(color: DiverrTheme.muted, height: 1.35)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: DiverrTheme.ocean.withOpacity(.28),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: DiverrTheme.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: DiverrTheme.muted, height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          children: [
            Icon(Icons.cloud_off_outlined, size: 46, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: DiverrTheme.muted, height: 1.4),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Carregando (skeleton)
// ============================================================

class SkeletonList extends StatefulWidget {
  final int count;
  final double height;
  const SkeletonList({super.key, this.count = 4, this.height = 96});

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final opacity = 0.35 + 0.35 * _c.value;
        return Column(
          children: List.generate(
            widget.count,
            (i) => Container(
              height: widget.height,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: DiverrTheme.ocean.withOpacity(opacity * .5),
                borderRadius: BorderRadius.circular(DiverrTheme.radius),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// Pequenos componentes
// ============================================================

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const StatCard({super.key, required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(DiverrTheme.radius),
        boxShadow: DiverrTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DiverrTheme.primary, size: 22),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: DiverrTheme.muted, fontSize: 13)),
        ],
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color? color;

  const InfoChip({super.key, this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? DiverrTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: c),
            const SizedBox(width: 5),
          ],
          Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class PlanBadge extends StatelessWidget {
  final bool premium;
  const PlanBadge({super.key, required this.premium});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: premium ? DiverrTheme.gold.withOpacity(.16) : DiverrTheme.muted.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (premium) const Icon(Icons.workspace_premium, size: 14, color: DiverrTheme.gold),
          if (premium) const SizedBox(width: 4),
          Text(
            premium ? 'PREMIUM' : 'FREE',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
              color: premium ? const Color(0xFF9A6B00) : DiverrTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estrelas de 0,5 a 5, em passos de meia estrela.
/// Somente leitura quando [onChanged] é null; senão, toque ou arraste para avaliar
/// (tocar de novo na mesma nota limpa a avaliação).
class RatingStars extends StatelessWidget {
  final double value; // 0..5 (aceita .5)
  final double size;
  final ValueChanged<double>? onChanged;

  const RatingStars({super.key, required this.value, this.size = 18, this.onChanged});

  IconData _iconFor(int i) {
    if (value >= i + 1) return Icons.star_rounded;
    if (value >= i + 0.5) return Icons.star_half_rounded;
    return Icons.star_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final interactive = onChanged != null;
    final gap = interactive ? 4.0 : 0.0;
    final step = size + gap;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Padding(
            padding: EdgeInsets.only(right: i < 4 ? gap : 0),
            child: Icon(
              _iconFor(i),
              size: size,
              color: value >= i + 0.5 ? DiverrTheme.gold : Colors.grey.shade400,
            ),
          ),
      ],
    );

    if (!interactive) return row;

    double fromDx(double dx) {
      final raw = (dx / step).clamp(0.0, 5.0);
      final v = (raw * 2).ceil() / 2;
      return v.clamp(0.5, 5.0);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) {
        final v = fromDx(d.localPosition.dx);
        onChanged!(v == value ? 0 : v);
      },
      onHorizontalDragUpdate: (d) => onChanged!(fromDx(d.localPosition.dx)),
      child: row,
    );
  }
}

/// Texto da nota: "4,5".
String formatRating(double? v) {
  if (v == null) return '—';
  final text = v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  return text.replaceAll('.', ',');
}

/// Imagem da rede com cache. As URLs do S3 mudam a cada resposta, então o cache usa o id da imagem.
class RemoteImage extends StatelessWidget {
  final String? url;
  final String? cacheKey;
  final BoxFit fit;
  final double? width;
  final double? height;
  final IconData placeholderIcon;

  /// Foto guardada no aparelho (mergulho ainda não sincronizado). Tem prioridade sobre [url].
  final String? localPath;

  const RemoteImage({
    super.key,
    required this.url,
    this.localPath,
    this.cacheKey,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderIcon = Icons.image_outlined,
  });

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: DiverrTheme.ocean.withOpacity(.25),
        child: Icon(placeholderIcon, color: DiverrTheme.primary.withOpacity(.6)),
      );

  @override
  Widget build(BuildContext context) {
    if (localPath != null) {
      return Image.file(
        File(localPath!),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    if (url == null) return _placeholder();
    return CachedNetworkImage(
      imageUrl: url!,
      cacheKey: cacheKey,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }
}

/// Visualizador em tela cheia com zoom.
Future<void> openImageViewer(BuildContext context, List<String?> urls, List<String> keys, int initial) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _ImageViewer(urls: urls, keys: keys, initial: initial),
    ),
  );
}

class _ImageViewer extends StatelessWidget {
  final List<String?> urls;
  final List<String> keys;
  final int initial;
  const _ImageViewer({required this.urls, required this.keys, required this.initial});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initial),
        itemCount: urls.length,
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: RemoteImage(url: urls[i], cacheKey: keys[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

/// Botão com loading embutido.
class LoadingButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;

  const LoadingButton({
    super.key,
    required this.loading,
    required this.onPressed,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Text(label),
              ],
            ),
    );
  }
}

/// Cartão com miniatura à esquerda cuja altura se ADAPTA ao conteúdo (mínimo [minHeight]).
/// Substitui os cartões de altura fixa, que estouravam por alguns pixels com fontes maiores.
class ImageSideCard extends StatelessWidget {
  final String? imageUrl;
  final String? cacheKey;
  final String? localPath;
  final IconData placeholderIcon;
  final double imageWidth;
  final double minHeight;
  final VoidCallback? onTap;
  final Widget child;
  final bool showChevron;

  const ImageSideCard({
    super.key,
    required this.imageUrl,
    this.cacheKey,
    this.localPath,
    this.placeholderIcon = Icons.image_outlined,
    this.imageWidth = 104,
    this.minHeight = 104,
    this.onTap,
    required this.child,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DiverrTheme.radius),
        boxShadow: DiverrTheme.softShadow,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: imageWidth,
                child: RemoteImage(
                  url: imageUrl,
                  cacheKey: cacheKey,
                  localPath: localPath,
                  placeholderIcon: placeholderIcon,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: imageWidth),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                          child: child,
                        ),
                      ),
                      if (showChevron)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.chevron_right, color: DiverrTheme.muted),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
