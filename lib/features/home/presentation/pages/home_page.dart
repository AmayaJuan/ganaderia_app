import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../animals/presentation/pages/animals_page.dart';
import '../../../lotes/presentation/pages/lotes_page.dart';
import '../../../reports/presentation/pages/reports_page.dart';
import '../../../../routes/app_routes.dart';
import '../../../../services/auth_service.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../models/nav_item.dart';
import '../widgets/dashboard_body.dart';
import '../widgets/offline_banner.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';
import '../../../health/presentation/pages/health_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isOnline = false;
  bool _simulateOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _connectivityDebounce;

  late final List<NavItem> _navItems;

  @override
  void initState() {
    _navItems = _buildNavItems();
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!AuthService.instance.isLoggedIn && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    });

    _refreshConnectivity(showFeedback: false);
    _connectivitySub = Connectivity().onConnectivityChanged.listen((_) {
      _connectivityDebounce?.cancel();
      _connectivityDebounce = Timer(
        const Duration(milliseconds: 500),
        () => _refreshConnectivity(showFeedback: true),
      );
    });
  }

  @override
  void dispose() {
    _connectivityDebounce?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _refreshConnectivity({required bool showFeedback}) async {
    if (_simulateOffline) {
      if (!mounted) return;
      final changed = _isOnline;
      setState(() => _isOnline = false);
      if (showFeedback) {
        _showSnackBar('Modo simulacion offline activo.', AppColors.brown);
      }
      if (changed) return;
      return;
    }

    final newOnlineState = await ConnectivityService.isOnline(
      simulateOffline: false,
    );

    if (!mounted) return;

    final changed = _isOnline != newOnlineState;
    setState(() => _isOnline = newOnlineState);

    if (!showFeedback) return;

    _showSnackBar(
      changed
          ? (newOnlineState
                ? 'Conexion restablecida. Sincronizando datos locales.'
                : 'Sin conexion. La app seguira funcionando en modo offline.')
          : (newOnlineState
                ? 'Ya estas en linea.'
                : 'Sigues sin conexion. Revisa tu red e intenta de nuevo.'),
      newOnlineState ? AppColors.green : AppColors.brown,
    );
  }

  void _showSnackBar(String message, Color color) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onTapConnectivity() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Conectividad',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Reintentar conexion'),
                subtitle: const Text('Verifica internet real en este equipo'),
                onTap: () => Navigator.pop(ctx, 'retry'),
              ),
              ListTile(
                leading: Icon(
                  _simulateOffline ? Icons.wifi : Icons.wifi_off,
                  color: AppColors.brown,
                ),
                title: Text(
                  _simulateOffline
                      ? 'Desactivar simulacion offline'
                      : 'Simular sin conexion',
                ),
                subtitle: const Text(
                  'Para pruebas mientras no hay red disponible',
                ),
                onTap: () => Navigator.pop(ctx, 'toggle_sim'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'retry') {
      await _refreshConnectivity(showFeedback: true);
      return;
    }

    if (action == 'toggle_sim') {
      setState(() {
        _simulateOffline = !_simulateOffline;
        if (_simulateOffline) _isOnline = false;
      });
      _showSnackBar(
        _simulateOffline
            ? 'Simulacion offline activada.'
            : 'Simulacion offline desactivada.',
        _simulateOffline ? AppColors.brown : AppColors.green,
      );
      if (!_simulateOffline) {
        await _refreshConnectivity(showFeedback: true);
      }
    }
  }

  void _onQuickAction(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          TopBar(isOnline: _isOnline, onTapWifi: _onTapConnectivity),
          if (!_isOnline) OfflineBanner(simulated: _simulateOffline),
          Expanded(
            child: isWide
                ? Row(
                    children: [
                      Sidebar(
                        items: _navItems,
                        selected: _selectedIndex,
                        onSelect: (i) => setState(() => _selectedIndex = i),
                      ),
                      Expanded(child: _getBody(_selectedIndex)),
                    ],
                  )
                : _getBody(_selectedIndex),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : SizedBox(
              height: 72,
              child: Row(
                children: [
                  Expanded(
                    child: BottomNavigationBar(
                      type: BottomNavigationBarType.fixed,
                      selectedItemColor: AppColors.green,
                      unselectedItemColor: Colors.grey,
                      currentIndex: _selectedIndex,
                      onTap: (i) => setState(() => _selectedIndex = i),
                      items: _navItems
                          .map(
                            (e) => BottomNavigationBarItem(
                              icon: Icon(e.icon),
                              label: e.label,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                    child: IconButton(
                      tooltip: 'Cerrar sesión',
                      icon: const Icon(Icons.logout, color: Colors.red),
                      onPressed: () async {
                        await AuthService.instance.logout();
                        if (!context.mounted) return;
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.login,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<NavItem> _buildNavItems() {
    final isAdmin = AuthService.instance.isAdmin;

    final items = <NavItem>[
      NavItem(icon: Icons.home, label: 'Inicio'),
      NavItem(icon: Icons.grid_view, label: 'Gestión de Lotes'),
      NavItem(icon: Icons.agriculture, label: 'Registro de Animales'),
      NavItem(icon: Icons.health_and_safety, label: 'Control sanitario'),
      NavItem(icon: Icons.bar_chart, label: 'Reportes'),
    ];

    if (isAdmin) {
      items.add(NavItem(icon: Icons.settings, label: 'Configuración'));
    }

    return items;
  }

  Widget _getBody(int index) {
    // El índice depende de si el admin está habilitado en el sidebar/bottom.
    // 0..4 siempre existen.
    if (index == 0) return DashboardBody(onQuickAction: _onQuickAction);
    if (index == 1) return const LotesPage();
    if (index == 2) return const AnimalsPage();
    if (index == 3) return const HealthPage();
    if (index == 4) return const ReportsPage();

    // Si el usuario es admin, el índice 5 será Configuración.
    if (index == 5 && AuthService.instance.isAdmin) {
      return const SettingsPage();
    }

    return DashboardBody(onQuickAction: _onQuickAction);
  }
}
