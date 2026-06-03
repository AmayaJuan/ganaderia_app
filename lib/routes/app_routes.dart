import 'package:flutter/material.dart';

import '../features/animals/presentation/pages/animals_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../screens/login/login_screen.dart';
class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String animals = '/animals';

  static Map<String, WidgetBuilder> get routes => {
        login: (_) => const LoginScreen(),
        home: (_) => const HomePage(),
        animals: (_) => const AnimalsPage(),
      };
}
