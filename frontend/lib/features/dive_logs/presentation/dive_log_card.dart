import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/ui/widgets.dart';
import '../data/dive_log_model.dart';

class DiveLogCard extends StatelessWidget {
  final DiveLogModel log;
  final VoidCallback onTap;
  const DiveLogCard({super.key, required this.log, required this.onTap});

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
          child: SizedBox(
            height: 108,
            child: Row(
              children: [
                SizedBox(
                  width: 108,
                  height: 108,
                  child: RemoteImage(
                    url: log.coverUrl,
                    cacheKey: log.imagens.isEmpty ? null : log.imagens.first.id,
                    placeholderIcon: Icons.scuba_diving,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          log.diveSiteNome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          formatDateTime(log.dataHora),
                          style: const TextStyle(color: DiverrTheme.muted, fontSize: 12.5),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (log.profundidadeMaxima != null)
                              InfoChip(icon: Icons.arrow_downward, text: formatMeters(log.profundidadeMaxima)),
                            if (log.duracaoMinutos != null)
                              InfoChip(icon: Icons.timer_outlined, text: formatDuration(log.duracaoMinutos), color: DiverrTheme.secondary),
                            if ((log.avaliacao ?? 0) > 0) RatingStars(value: log.avaliacao!, size: 15),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.chevron_right, color: DiverrTheme.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
