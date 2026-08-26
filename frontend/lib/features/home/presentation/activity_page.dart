import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
        children: [
          const Text(
            'Atividade',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: DiverrTheme.dark,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Acompanhe sua evolução como mergulhador.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              _metric('0', 'Mergulhos'),
              _metric('0 m', 'Profundidade'),
              _metric('0 h', 'Tempo'),
            ],
          ),

          const SizedBox(height: 18),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.insights_outlined,
                    size: 48,
                    color: DiverrTheme.secondary,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Suas estatísticas aparecerão aqui',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Depois que você registrar alguns mergulhos, '
                        'vamos transformar seus dados em estatísticas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 8,
          ),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: DiverrTheme.dark,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}