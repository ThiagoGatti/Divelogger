import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/session/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSession.instance.restore();
  runApp(const DiverrApp());
}
