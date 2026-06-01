import 'package:flutter/material.dart';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import '../../../../routes/app_routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  static const _green = Color(0xFF20A67A);
  bool _isOnline = false; // Simulación de estado de conexión

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (mounted) {
        setState(
          () =>
              _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isOnline = false);
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
          _TopBar(isOnline: _isOnline, onTapWifi: _checkConnectivity),

          // ── Banner offline ──
          if (!_isOnline) _OfflineBanner(),
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
                : _DashboardBody(),
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
        return _DashboardBody();
      case 1:
        return const _LotesBody();
      case 2:
        return const Center(child: Text('Registro de Animales - próximamente'));
      case 3:
        return const Center(child: Text('Control Sanitario - próximamente'));
      case 4:
        return const Center(child: Text('Reportes - próximamente'));
      default:
        return _DashboardBody();
    }
  }
}

// ── TOP BAR ─────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onTapWifi;
  const _TopBar({required this.isOnline, required this.onTapWifi});

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
                    isOnline ? 'En línea' : 'Sin conexión',
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
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF7A4500),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: const Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sin conexión a internet. Los datos se guardarán localmente '
              'y se sincronizarán automáticamente al reconectar.',
              style: TextStyle(color: Colors.white, fontSize: 12),
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
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.monitor_weight,
                  label: 'Registrar Peso',
                  color: const Color(0xFF20A67A),
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.grid_view,
                  label: 'Gestionar Lotes',
                  color: const Color(0xFF185FA5),
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.bar_chart,
                  label: 'Ver Reportes',
                  color: const Color(0xFF7A4500),
                  onTap: () {},
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
  }) : animales = 0;
}

class _LotesBody extends StatefulWidget {
  const _LotesBody();

  @override
  State<_LotesBody> createState() => _LotesBodyState();
}

class _LotesBodyState extends State<_LotesBody> {
  static const _green = Color(0xFF20A67A);
  final List<_LoteModel> _lotes = [];

   @override
Widget build(BuildContext context) {
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
              setState(() {
                if (esEdicion) {
                  lote.nombre = nombreCtrl.text.trim();
                  lote.descripcion = descCtrl.text.trim();
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
