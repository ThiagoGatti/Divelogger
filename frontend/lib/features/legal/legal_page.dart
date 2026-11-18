import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'legal_content.dart';

/// Tela de leitura da Política de Privacidade / Termos de Uso.
class LegalPage extends StatelessWidget {
  final LegalDocument document;
  const LegalPage({super.key, required this.document});

  static Route<void> privacy() =>
      MaterialPageRoute(builder: (_) => const LegalPage(document: kPrivacyPolicy));

  static Route<void> terms() =>
      MaterialPageRoute(builder: (_) => const LegalPage(document: kTermsOfUse));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          Text(document.updated, style: const TextStyle(color: DiverrTheme.muted, fontSize: 12.5)),
          const SizedBox(height: 12),
          Text(document.intro, style: const TextStyle(height: 1.5)),
          for (final s in document.sections) ...[
            const SizedBox(height: 22),
            Text(s.heading, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            for (final p in s.paragraphs)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(p, style: const TextStyle(height: 1.5)),
              ),
          ],
        ],
      ),
    );
  }
}
