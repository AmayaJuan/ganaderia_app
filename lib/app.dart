import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'services/auth_service.dart';

class GanaderiaApp extends StatelessWidget {
  const GanaderiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GanaderíaApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AuthService.instance.isLoggedIn
          ? AppRoutes.home
          : AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}