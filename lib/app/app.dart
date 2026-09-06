import 'package:flutter/material.dart';

import '../features/auth/presentation/pages/login_page.dart';
import 'theme/app_theme.dart';

/// Punto de configuración de la aplicación (tema, rutas, localización).
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prueba Periferia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginPage(),
    );
  }
}
