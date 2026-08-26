import 'package:flutter/material.dart';

class DiveLogsPage extends StatelessWidget {
  const DiveLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Text(
          'Meus Mergulhos',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}