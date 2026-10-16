import 'package:flutter/material.dart';

import '../../../core/ui/widgets.dart';

/// Atividade dos amigos: o feed (mergulhos de quem você segue, curtidas com emoji e comentários)
/// chega junto com o sistema de seguidores, na próxima entrega.
class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Amigos',
              subtitle: 'Acompanhe os mergulhos de quem você segue.',
            ),
            EmptyState(
              icon: Icons.group_outlined,
              title: 'Em breve',
              message:
                  'Siga outros mergulhadores, veja os mergulhos deles, reaja com emojis e comente. '
                  'Você já pode definir quem vê seus mergulhos em Perfil → Configurações.',
            ),
          ],
        ),
      ),
    );
  }
}
