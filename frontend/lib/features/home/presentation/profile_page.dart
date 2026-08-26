import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/session/session.dart';
import '../../landing/presentation/landing_page.dart';

class ProfilePage extends StatelessWidget {
 const ProfilePage({super.key});

 @override
 Widget build(BuildContext context) {
  final user = AppSession.instance.currentUser;

  return SafeArea(
   child: ListView(
    padding: const EdgeInsets.fromLTRB(
     20,
     18,
     20,
     100,
    ),
    children: [
     const Text(
      'Perfil',
      style: TextStyle(
       fontSize: 28,
       fontWeight: FontWeight.w800,
       color: DiverrTheme.dark,
      ),
     ),

     const SizedBox(height: 20),

     Card(
      child: Padding(
       padding: const EdgeInsets.all(20),
       child: Row(
        children: [
         Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
           color: DiverrTheme.ocean,
           shape: BoxShape.circle,
          ),
          child: const Icon(
           Icons.person,
           size: 34,
           color: DiverrTheme.primary,
          ),
         ),

         const SizedBox(width: 16),

         Expanded(
          child: Column(
           crossAxisAlignment:
           CrossAxisAlignment.start,
           children: [
            Text(
             user?.nomeCompleto ??
                 'Mergulhador',
             style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
             ),
            ),

            const SizedBox(height: 4),

            Text(
             user?.email ?? '',
             style: TextStyle(
              color: Colors.grey.shade600,
             ),
            ),

            const SizedBox(height: 6),

            Text(
             'Plano ${user?.plano ?? 'FREE'}',
             style: const TextStyle(
              color: DiverrTheme.primary,
              fontWeight: FontWeight.w700,
             ),
            ),
           ],
          ),
         ),
        ],
       ),
      ),
     ),

     const SizedBox(height: 14),

     _item(
      icon: Icons.settings_outlined,
      title: 'Configurações',
     ),

     _item(
      icon: Icons.help_outline,
      title: 'Ajuda',
     ),

     _item(
      icon: Icons.logout,
      title: 'Sair',
      onTap: () {
       AppSession.instance.currentUser = null;

       Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
         builder: (_) => const LandingPage(),
        ),
            (route) => false,
       );
      },
     ),
    ],
   ),
  );
 }

 Widget _item({
  required IconData icon,
  required String title,
  VoidCallback? onTap,
 }) {
  return Card(
   child: ListTile(
    onTap: onTap,
    leading: Icon(
     icon,
     color: DiverrTheme.primary,
    ),
    title: Text(
     title,
     style: const TextStyle(
      fontWeight: FontWeight.w600,
     ),
    ),
    trailing: const Icon(
     Icons.chevron_right,
    ),
   ),
  );
 }
}