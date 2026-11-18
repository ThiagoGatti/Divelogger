import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/offline/sites_cache.dart';
import 'core/offline/sync_service.dart';
import 'core/session/session.dart';
import 'core/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.load();
  await AppSession.instance.restore();
  await SitesCache.init();
  SyncService.instance.start();
  runApp(const DiverrApp());
}
