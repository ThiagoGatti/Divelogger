import 'package:flutter/material.dart';
import '../features/landing/presentation/landing_page.dart';
import 'theme.dart';

class DiverrApp extends StatelessWidget {
  const DiverrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diverr',
      theme: DiverrTheme.light,
      home: const LandingPage(),
    );
  }
}