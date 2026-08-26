import 'package:flutter/material.dart';

class DiveSitesPage extends StatelessWidget {
  const DiveSitesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Text(
          'Dive Sites',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}