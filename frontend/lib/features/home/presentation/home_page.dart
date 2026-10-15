import 'package:flutter/material.dart';

import '../../../core/events.dart';
import '../../../core/session/session.dart';
import '../../auth/data/me_api.dart';
import 'activity_page.dart';
import 'create_dive_site_page.dart';
import 'dive_logs_page.dart';
import 'dive_sites_page.dart';
import 'map_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _pages = <Widget>[
    MapPage(),
    DiveLogsPage(),
    ActivityPage(),
    DiveSitesPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Atualiza role/plano/limites com o que o servidor diz agora (o token pode estar desatualizado).
    MeApi().refresh();
  }

  Future<void> _createSite() async {
    final site = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateDiveSitePage()),
    );
    if (site != null) AppEvents.notifyDiveSitesChanged();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppSession.instance.changed,
      builder: (context, _, __) {
        final showSiteFab = _index == 0 && AppSession.instance.isAdmin;

        return Scaffold(
          // IndexedStack mantém o estado de cada aba (mapa, listas) ao trocar de aba.
          body: IndexedStack(index: _index, children: _pages),
          floatingActionButton: showSiteFab
              ? FloatingActionButton.extended(
                  onPressed: _createSite,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Novo local', style: TextStyle(fontWeight: FontWeight.w800)),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Mapa',
              ),
              NavigationDestination(
                icon: Icon(Icons.scuba_diving_outlined),
                selectedIcon: Icon(Icons.scuba_diving),
                label: 'Mergulhos',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Atividade',
              ),
              NavigationDestination(
                icon: Icon(Icons.location_on_outlined),
                selectedIcon: Icon(Icons.location_on),
                label: 'Sites',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        );
      },
    );
  }
}
