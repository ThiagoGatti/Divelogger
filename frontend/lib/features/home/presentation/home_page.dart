import 'package:flutter/material.dart';

import '../../../core/session/session.dart';
import '../../auth/data/me_api.dart';
import '../../dive_logs/presentation/dive_log_form_page.dart';
import '../../social/presentation/friends_page.dart';
import 'create_dive_site_page.dart';
import 'dive_site_details_page.dart';
import 'dive_sites_page.dart';
import 'map_page.dart';
import 'profile_page.dart';
import '../../../core/events.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _pages = <Widget>[
    MapPage(),
    DiveSitesPage(),
    FriendsPage(),
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
    if (site == null || !mounted) return;
    AppEvents.notifyDiveSitesChanged();

    // Abre o local recém-criado para o admin já adicionar as fotos.
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DiveSiteDetailsPage(site: site)),
    );
    AppEvents.notifyDiveSitesChanged();
  }

  Widget? _fab() {
    final admin = AppSession.instance.isAdmin;

    // Explorar: admin cria local; usuário comum registra mergulho.
    if (_index == 0) {
      return admin
          ? FloatingActionButton.extended(
              heroTag: 'fab-site',
              onPressed: _createSite,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Novo local', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null;
    }

    // Amigos e Perfil: registrar mergulho.
    if (_index == 2 || _index == 3) {
      return FloatingActionButton.extended(
        heroTag: 'fab-dive',
        onPressed: () => openDiveLogForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo mergulho', style: TextStyle(fontWeight: FontWeight.w800)),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppSession.instance.changed,
      builder: (context, _, __) {
        return Scaffold(
          // IndexedStack mantém o estado de cada aba (mapa, listas) ao trocar de aba.
          body: IndexedStack(index: _index, children: _pages),
          floatingActionButton: _fab(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Explorar',
              ),
              NavigationDestination(
                icon: Icon(Icons.location_on_outlined),
                selectedIcon: Icon(Icons.location_on),
                label: 'Sites',
              ),
              NavigationDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group),
                label: 'Amigos',
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
