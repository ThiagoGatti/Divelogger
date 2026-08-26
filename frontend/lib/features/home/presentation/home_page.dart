import 'package:flutter/material.dart';
import '../../../app/theme.dart';

import 'map_page.dart';
import 'dive_logs_page.dart';
import 'activity_page.dart';
import 'dive_sites_page.dart';
import 'profile_page.dart';
import 'wave_bottom_bar.dart';
import 'create_dive_site_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      const MapPage(),
      const DiveLogsPage(),
      const ActivityPage(),
      const DiveSitesPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],

      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton(
        onPressed: () async {
          final site = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateDiveSitePage(),
            ),
          );

          if (!mounted || site == null) {
            return;
          }

          setState(() {});
        },
        backgroundColor: DiverrTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      )
          : null,

      bottomNavigationBar: WaveBottomBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
    );
  }
}