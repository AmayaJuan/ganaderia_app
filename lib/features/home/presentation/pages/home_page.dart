import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../routes/app_routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  static const _green = Color(0xFF20A67A);
  bool _isOnline = false;
  bool _simulateOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _connectivityDebounce;

  @override
  void initState() {
    super.initState();
    _refreshConnectivity(showFeedback: false);
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((_) {
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

  Future<bool> _hasInternetAccess() async {
    // En Windows algunas redes bloquean generate_204; usamos varios checks.
    try {
      final dnsGoogle = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      if (dnsGoogle.isNotEmpty && dnsGoogle.first.rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    try {
      final dnsCloudflare = await InternetAddress.lookup(
        'one.one.one.one',
      ).timeout(const Duration(seconds: 3));
      if (dnsCloudflare.isNotEmpty &&
          dnsCloudflare.first.rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    try {
      final uri = Uri.parse('https://clients3.google.com/generate_204');
      final response =
          await http.get(uri).timeout(const Duration(seconds: 3));
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _refreshConnectivity({required bool showFeedback}) async {
    if (_simulateOffline) {
      if (!mounted) return;
      final changed = _isOnline;
      setState(() => _isOnline = false);
      if (showFeedback) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Modo simulacion offline activo.'),
            backgroundColor: Color(0xFF7A4500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (changed) return;
      return;
    }

    final connectivityResults = await Connectivity().checkConnectivity();
    final hasNetworkInterface = connectivityResults
        .any((result) => result != ConnectivityResult.none);
    final newOnlineState =
        hasNetworkInterface && await _hasInternetAccess();

    if (!mounted) return;

    final changed = _isOnline != newOnlineState;
    setState(() => _isOnline = newOnlineState);

    if (!showFeedback) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          changed
              ? (newOnlineState
                  ? 'Conexion restablecida. Sincronizando datos locales.'
                  : 'Sin conexion. La app seguira funcionando en modo offline.')
              : (newOnlineState
                  ? 'Ya estas en linea.'
                  : 'Sigues sin conexion. Revisa tu red e intenta de nuevo.'),
        ),
        backgroundColor: newOnlineState
            ? const Color(0xFF20A67A)
            : const Color(0xFF7A4500),
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
                  color: const Color(0xFF7A4500),
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
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _simulateOffline
                ? 'Simulacion offline activada.'
                : 'Simulacion offline desactivada.',
          ),
          backgroundColor: _simulateOffline
              ? const Color(0xFF7A4500)
              : const Color(0xFF20A67A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (!_simulateOffline) {
        await _refreshConnectivity(showFeedback: true);
      }
    }
  }

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home, label: 'Inicio'),
    _NavItem(icon: Icons.grid_view, label: 'Gestión de Lotes'),
    _NavItem(icon: Icons.pets, label: 'Registro de Animales'),
    _NavItem(icon: Icons.medical_services, label: 'Control Sanitario'),
    _NavItem(icon: Icons.bar_chart, label: 'Reportes'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── TopBar ──
          _TopBar(
            isOnline: _isOnline,
            simulateOffline: _simulateOffline,
            onTapWifi: _onTapConnectivity,
          ),

          // ── Banner offline ──
          if (!_isOnline) _OfflineBanner(simulated: _simulateOffline),
          // ── Cuerpo ──
          Expanded(
            child: isWide
                ? Row(
                    children: [
                      _Sidebar(
                        items: _navItems,
                        selected: _selectedIndex,
                        onSelect: (i) => setState(() => _selectedIndex = i),
                      ),
                      Expanded(child: _getBody(_selectedIndex)),
                    ],
                  )
                : _DashboardBody(
                    onQuickAction: (index) =>
                        setState(() => _selectedIndex = index),
                  ),
          ),
        ],
      ),
      // Navegación móvil
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedItemColor: _green,
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
    );
  }

  Widget _getBody(int index) {
    switch (index) {
      case 0:
        return _DashboardBody(
          onQuickAction: (index) => setState(() => _selectedIndex = index),
        );
      case 1:
        return const _LotesBody();
      case 2:
        return const _AnimalsBody();
      case 3:
        return const _HealthBody();
      case 4:
        return const _ReportsBody();
      default:
        return _DashboardBody(
          onQuickAction: (index) => setState(() => _selectedIndex = index),
        );
    }
  }
}

class _AnimalsBody extends StatelessWidget {
  const _AnimalsBody();

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('#1', 'Brahman', 'Macho', '3 anios', 'Lote Norte', '420 kg'),
      ('#2', 'Cebu', 'Hembra', '3 anios', 'Lote Sur', '375 kg'),
      ('#3', 'Angus', 'Macho', '2 anios', 'Lote Este', '342 kg'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registro de Animales',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF20A67A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gestione el inventario bovino',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Animal'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por raza o lote...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Raza')),
                  DataColumn(label: Text('Sexo')),
                  DataColumn(label: Text('Edad')),
                  DataColumn(label: Text('Lote')),
                  DataColumn(label: Text('Peso Actual')),
                ],
                rows: rows
                    .map(
                      (r) => DataRow(
                        cells: [
                          DataCell(Text(r.$1)),
                          DataCell(Text(r.$2)),
                          DataCell(Text(r.$3)),
                          DataCell(Text(r.$4)),
                          DataCell(Text(r.$5)),
                          DataCell(Text(r.$6)),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthBody extends StatelessWidget {
  const _HealthBody();

  @override
  Widget build(BuildContext context) {
    final alerts = [
      ('Cebu #2', 'Perdida de peso detectada'),
      ('Brahman #1', 'Vacuna pendiente'),
      ('Angus #3', 'Control sanitario atrasado'),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Control Sanitario',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF20A67A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Alertas y seguimientos del estado de salud',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: alerts.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = alerts[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE7D5A0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Color(0xFF9A6A00)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${item.$1}: ${item.$2}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Ver historial'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  const _ReportsBody();

  @override
  Widget build(BuildContext context) {
    Widget reportCard({
      required String title,
      required String subtitle,
      required bool active,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF20A67A) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6E6E6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.insert_chart_outlined,
                color: active ? Colors.white : const Color(0xFF20A67A),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: active ? Colors.white70 : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reportes',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF20A67A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Analisis y estadisticas del ganado',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              reportCard(
                title: 'Reporte de Peso',
                subtitle: 'Analisis de peso promedio por lote',
                active: true,
              ),
              const SizedBox(width: 12),
              reportCard(
                title: 'Reporte Sanitario',
                subtitle: 'Vacunas y tratamientos aplicados',
                active: false,
              ),
              const SizedBox(width: 12),
              reportCard(
                title: 'Inventario General',
                subtitle: 'Distribucion por raza y lote',
                active: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── TOP BAR ─────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool isOnline;
  final bool simulateOffline;
  final VoidCallback onTapWifi;
  const _TopBar({
    required this.isOnline,
    required this.simulateOffline,
    required this.onTapWifi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Text(
            'GanaderíaApp',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF20A67A),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onTapWifi,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isOnline
                    ? const Color(0xFFE1F5EE)
                    : const Color(0xFFFCEBEB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    isOnline ? Icons.wifi : Icons.wifi_off,
                    size: 16,
                    color: isOnline
                        ? const Color(0xFF20A67A)
                        : const Color(0xFFA32D2D),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOnline
                        ? 'En línea'
                        : 'Sin conexión',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isOnline
                          ? const Color(0xFF20A67A)
                          : const Color(0xFFA32D2D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── BANNER OFFLINE ───────────────────────────────────
class _OfflineBanner extends StatelessWidget {
  final bool simulated;
  const _OfflineBanner({this.simulated = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF7A4500),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              simulated
                  ? 'Modo sin conexion simulado activo. Los datos se guardan localmente '
                      'mientras pruebas el flujo offline.'
                  : 'Sin conexión a internet. Los datos se guardarán localmente '
                      'y se sincronizarán automáticamente al reconectar.',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SIDEBAR ──────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selected;
  final ValueChanged<int> onSelect;

  const _Sidebar({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 8),
          ...List.generate(items.length, (i) {
            final active = i == selected;
            return GestureDetector(
              onTap: () => onSelect(i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF20A67A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      items[i].icon,
                      color: active ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        items[i].label,
                        style: TextStyle(
                          color: active ? Colors.white : Colors.black87,
                          fontWeight: active
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Spacer(),
          // Cerrar sesión
          GestureDetector(
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.login),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: const Row(
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── DASHBOARD BODY ───────────────────────────────────
class _DashboardBody extends StatelessWidget {
  final ValueChanged<int> onQuickAction;

  const _DashboardBody({required this.onQuickAction});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Text(
            'Panel de Control',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF20A67A),
            ),
          ),
          const Text(
            'Resumen de actividad ganadera',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),

          // Banner guardado automático
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE1F5EE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF20A67A)),
            ),
            child: const Row(
              children: [
                Icon(Icons.save, color: Color(0xFF20A67A), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '📋 Guardado automático activado: '
                    'Todos tus registros se guardan localmente en tu '
                    'dispositivo y permanecen aunque cierres la aplicación.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF20A67A)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tarjetas estadísticas
          Row(
            children: const [
              Expanded(
                child: _StatCard(
                  label: 'Total Animales',
                  value: '0',
                  icon: Icons.pets,
                  color: Color(0xFF20A67A),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Lotes Activos',
                  value: '0',
                  icon: Icons.grid_view,
                  color: Color(0xFF185FA5),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Peso Promedio',
                  value: '0 kg',
                  icon: Icons.monitor_weight,
                  color: Color(0xFF20A67A),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Controles Sanitarios',
                  value: '0',
                  icon: Icons.medical_services,
                  color: Color(0xFF7A4500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Gráficas
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barras
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Peso Promedio por Lote',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 600,
                            barGroups: [
                              _bar(0, 420),
                              _bar(1, 350),
                              _bar(2, 330),
                              _bar(3, 0),
                            ],
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, _) {
                                    const labels = [
                                      'L. Norte',
                                      'L. Sur',
                                      'L. Este',
                                      'L. Oeste',
                                    ];
                                    return Text(
                                      labels[v.toInt()],
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 150,
                                  getTitlesWidget: (v, _) => Text(
                                    v.toInt().toString(),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: const FlGridData(drawVerticalLine: false),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Torta
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Distribución por Raza',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: 33,
                                color: const Color(0xFF20A67A),
                                title: 'Brahman\n33%',
                                titleStyle: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF20A67A),
                                ),
                                titlePositionPercentageOffset: 1.4,
                                radius: 60,
                              ),
                              PieChartSectionData(
                                value: 33,
                                color: const Color(0xFF185FA5),
                                title: 'Cebú\n33%',
                                titleStyle: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF185FA5),
                                ),
                                titlePositionPercentageOffset: 1.4,
                                radius: 60,
                              ),
                              PieChartSectionData(
                                value: 33,
                                color: const Color(0xFF7A4500),
                                title: 'Angus\n33%',
                                titleStyle: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF7A4500),
                                ),
                                titlePositionPercentageOffset: 1.4,
                                radius: 60,
                              ),
                            ],
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Actividad reciente
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Actividad Reciente',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                _activityItem(
                  Icons.pets,
                  const Color(0xFF20A67A),
                  'No hay animales registrados',
                  'Registra tu primer animal',
                ),
                _activityItem(
                  Icons.grid_view,
                  const Color(0xFF185FA5),
                  'No hay lotes creados',
                  'Crea tu primer lote',
                ),
                _activityItem(
                  Icons.medical_services,
                  const Color(0xFF7A4500),
                  'No hay controles sanitarios',
                  'Registra el primer control',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Acciones rápidas
          const Text(
            'Acciones Rápidas',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.add,
                  label: 'Registrar Animal',
                  color: const Color(0xFF20A67A),
                  onTap: () => onQuickAction(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.monitor_weight,
                  label: 'Registrar Peso',
                  color: const Color(0xFF20A67A),
                  onTap: () => onQuickAction(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.grid_view,
                  label: 'Gestionar Lotes',
                  color: const Color(0xFF185FA5),
                  onTap: () => onQuickAction(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.bar_chart,
                  label: 'Ver Reportes',
                  color: const Color(0xFF7A4500),
                  onTap: () => onQuickAction(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFF20A67A),
          width: 30,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _activityItem(IconData icon, Color color, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.1),

            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── STAT CARD ────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),

                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ACTION BUTTON ────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── HELPERS ──────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ── LOTES BODY ───────────────────────────────────────
class _LoteModel {
  final String id;
  String nombre;
  String descripcion;
  int animales;

  _LoteModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.animales = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'animales': animales,
      };

  factory _LoteModel.fromJson(Map<String, dynamic> json) {
    return _LoteModel(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      animales: json['animales'] is int
          ? json['animales'] as int
          : int.tryParse('${json['animales']}') ?? 0,
    );
  }
}

class _LotesBody extends StatefulWidget {
  const _LotesBody();

  @override
  State<_LotesBody> createState() => _LotesBodyState();
}

class _LotesBodyState extends State<_LotesBody> {
  static const _green = Color(0xFF20A67A);
  static const _storageKey = 'home_lotes_v1';
  final List<_LoteModel> _lotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLotes();
  }

  Future<void> _loadLotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (!mounted) return;

    if (raw == null || raw.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final parsed = decoded
            .whereType<Map>()
            .map((item) => _LoteModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        setState(() {
          _lotes
            ..clear()
            ..addAll(parsed);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_lotes.map((l) => l.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  @override
  Widget build(BuildContext context) {
  if (_isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Encabezado
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gestión de Lotes',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF20A67A))),
                Text('Administre las áreas de pastoreo',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Lote'),
              onPressed: () => _mostrarFormulario(),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),

      // Lista
      Expanded(
        child: _lotes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE1F5EE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.grass,
                          size: 48, color: Color(0xFF20A67A)),
                    ),
                    const SizedBox(height: 16),
                    const Text('No hay lotes registrados',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                        'Crea tu primer lote para organizar el ganado',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Crear primer lote'),
                      onPressed: () => _mostrarFormulario(),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _lotes.length,
                  itemBuilder: (ctx, i) {
                    final lote = _lotes[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE1F5EE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.grass,
                                    color: Color(0xFF20A67A), size: 20),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Color(0xFF185FA5), size: 18),
                                onPressed: () =>
                                    _mostrarFormulario(lote: lote),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 18),
                                onPressed: () =>
                                    _confirmarEliminar(lote),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(lote.nombre,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
                          if (lote.descripcion.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(lote.descripcion,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(Icons.pets,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('${lote.animales} animales',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                              const Spacer(),
                              const Text('Ver animales',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF20A67A),
                                      fontWeight: FontWeight.bold)),
                              const Icon(Icons.keyboard_arrow_down,
                                  color: Color(0xFF20A67A), size: 16),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    ],
  );
  }

  void _mostrarFormulario({_LoteModel? lote}) {
    final nombreCtrl =
        TextEditingController(text: lote?.nombre ?? '');
    final descCtrl =
        TextEditingController(text: lote?.descripcion ?? '');
    final formKey = GlobalKey<FormState>();
    final esEdicion = lote != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(esEdicion ? Icons.edit : Icons.add_circle,
                color: const Color(0xFF20A67A)),
            const SizedBox(width: 8),
            Text(esEdicion ? 'Editar Lote' : 'Nuevo Lote'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nombre del lote *',
                    hintText: 'Ej: Lote Norte',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => v!.trim().isEmpty
                      ? 'El nombre es obligatorio'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Ej: Área de pastoreo rotativo',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF20A67A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final loteActual = lote;
              setState(() {
                if (esEdicion && loteActual != null) {
                  loteActual.nombre = nombreCtrl.text.trim();
                  loteActual.descripcion = descCtrl.text.trim();
                } else {
                  _lotes.add(_LoteModel(
                    id: DateTime.now()
                        .millisecondsSinceEpoch
                        .toString(),
                    nombre: nombreCtrl.text.trim(),
                    descripcion: descCtrl.text.trim(),
                  ));
                }
              });
              unawaited(_saveLotes());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      esEdicion ? 'Lote actualizado' : 'Lote creado'),
                  backgroundColor: const Color(0xFF20A67A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child:
                Text(esEdicion ? 'Guardar cambios' : 'Crear lote'),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(_LoteModel lote) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar lote'),
          ],
        ),
        content: Text(
            '¿Estás seguro de eliminar "${lote.nombre}"?\n'
            'Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() => _lotes.remove(lote));
              unawaited(_saveLotes());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Lote eliminado'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
