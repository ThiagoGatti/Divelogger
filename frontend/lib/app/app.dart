import 'package:flutter/material.dart';

import '../core/session/session.dart';
import '../features/home/presentation/home_page.dart';
import '../features/landing/presentation/landing_page.dart';
import '../core/theme_controller.dart';
import 'theme.dart';

class DiverrApp extends StatefulWidget {
  const DiverrApp({super.key});

  @override
  State<DiverrApp> createState() => _DiverrAppState();
}

class _DiverrAppState extends State<DiverrApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    AppSession.instance.sessionExpired.addListener(_onSessionExpired);
  }

  @override
  void dispose() {
    AppSession.instance.sessionExpired.removeListener(_onSessionExpired);
    super.dispose();
  }

  // 401 em qualquer chamada => volta para a tela inicial.
  void _onSessionExpired() {
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) => MaterialApp(
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Diverr',
        theme: DiverrTheme.light,
        darkTheme: DiverrTheme.darkTheme,
        themeMode: mode,
        home: AppSession.instance.isLoggedIn ? const HomePage() : const LandingPage(),
      ),
    );
  }
}
