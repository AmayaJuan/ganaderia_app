import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'core/theme/app_theme.dart';

class GanaderiaApp extends StatelessWidget {
  const GanaderiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GanaderíaApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,,
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}