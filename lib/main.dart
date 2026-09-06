import 'package:flutter/material.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Arranca ya: las notificaciones se inicializan en segundo plano al usarse.
  runApp(const App());
}
