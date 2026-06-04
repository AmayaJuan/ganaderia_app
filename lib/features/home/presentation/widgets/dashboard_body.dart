import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import 'action_button.dart';
import 'stat_card.dart';

class DashboardBody extends StatefulWidget {
  final ValueChanged<int> onQuickAction;

  const DashboardBody({super.key, required this.onQuickAction});

  @override
  State<DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<DashboardBody> {
  final _db = Supabase.instance.client;

  // ── Stats ──────────────────────────────────────────
  int _totalAnimales = 0;
  int _totalLotes = 0;
  double _pesoPromedio = 0;
  int _controlesSanitarios = 0;

  // ── Gráfica barras: peso promedio por lote ──────────
  List<_LoteStat> _loteStats = [];

  // ── Gráfica pie: distribución por raza ─────────────
  List<_RazaStat> _razaStats = [];

  // ── Actividad reciente ──────────────────────────────
  List<_ActividadItem> _actividad = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      // ── 1. Totales ────────────────────────────────────
      final animalesData = await _db
          .from('animales')
          .select('id, raza, id_lote, registro_peso(peso, fecha)');

      final lotesData = await _db.from('lotes').select('id, nombre');

      final sanitariosData = await _db.from('registro_sanitario').select('id');

      final animales = animalesData as List;
      final lotes = lotesData as List;
      final sanitarios = sanitariosData as List;

      _totalAnimales = animales.length;
      _totalLotes = lotes.length;
      _controlesSanitarios = sanitarios.length;

      // ── 2. Peso promedio global ───────────────────────
      final todosLosPesos = <double>[];
      for (final a in animales) {
        final pesos = a['registro_peso'] as List?;
        if (pesos != null && pesos.isNotEmpty) {
          pesos.sort(
            (x, y) => (y['fecha'] as String).compareTo(x['fecha'] as String),
          );
          todosLosPesos.add((pesos.first['peso'] as num).toDouble());
        }
      }
      _pesoPromedio = todosLosPesos.isEmpty
          ? 0
          : todosLosPesos.reduce((a, b) => a + b) / todosLosPesos.length;

      // ── 3. Peso promedio por lote ─────────────────────
      final Map<String, String> loteNombres = {
        for (final l in lotes) l['id'] as String: l['nombre'] as String,
      };
      final Map<String, List<double>> pesosPorLote = {};

      for (final a in animales) {
        final idLote = a['id_lote'] as String?;
        if (idLote == null) continue;
        final pesos = a['registro_peso'] as List?;
        if (pesos == null || pesos.isEmpty) continue;
        pesos.sort(
          (x, y) => (y['fecha'] as String).compareTo(x['fecha'] as String),
        );
        final ultimo = (pesos.first['peso'] as num).toDouble();
        pesosPorLote.putIfAbsent(idLote, () => []).add(ultimo);
      }

      _loteStats = pesosPorLote.entries.map((e) {
        final avg = e.value.reduce((a, b) => a + b) / e.value.length;
        return _LoteStat(
          nombre: loteNombres[e.key] ?? e.key.substring(0, 6),
          promedio: avg,
        );
      }).toList()..sort((a, b) => b.promedio.compareTo(a.promedio));

      // ── 4. Distribución por raza ──────────────────────
      final Map<String, int> razaCount = {};
      for (final a in animales) {
        final raza = (a['raza'] as String?)?.trim() ?? 'Otra';
        razaCount[raza] = (razaCount[raza] ?? 0) + 1;
      }
      final colors = [
        AppColors.green,
        AppColors.blue,
        AppColors.brown,
        Colors.orange,
        Colors.purple,
        Colors.teal,
      ];
      int ci = 0;
      _razaStats = razaCount.entries.map((e) {
        final color = colors[ci % colors.length];
        ci++;
        return _RazaStat(
          raza: e.key,
          cantidad: e.value,
          porcentaje: animales.isEmpty
              ? 0
              : (e.value / animales.length * 100).roundToDouble(),
          color: color,
        );
      }).toList()..sort((a, b) => b.cantidad.compareTo(a.cantidad));

      // ── 5. Actividad reciente ─────────────────────────
      _actividad = [];

      if (animales.isNotEmpty) {
        _actividad.add(
          _ActividadItem(
            icon: Icons.pets,
            color: AppColors.green,
            title:
                '$_totalAnimales animal${_totalAnimales != 1 ? 'es' : ''} registrado${_totalAnimales != 1 ? 's' : ''}',
            sub: 'Último ingreso en el sistema',
          ),
        );
      } else {
        _actividad.add(
          _ActividadItem(
            icon: Icons.pets,
            color: AppColors.green,
            title: 'No hay animales registrados',
            sub: 'Registra tu primer animal',
          ),
        );
      }

      if (lotes.isNotEmpty) {
        _actividad.add(
          _ActividadItem(
            icon: Icons.grid_view,
            color: AppColors.blue,
            title:
                '$_totalLotes lote${_totalLotes != 1 ? 's' : ''} activo${_totalLotes != 1 ? 's' : ''}',
            sub: 'Áreas de pastoreo configuradas',
          ),
        );
      } else {
        _actividad.add(
          _ActividadItem(
            icon: Icons.grid_view,
            color: AppColors.blue,
            title: 'No hay lotes creados',
            sub: 'Crea tu primer lote',
          ),
        );
      }

      if (sanitarios.isNotEmpty) {
        _actividad.add(
          _ActividadItem(
            icon: Icons.medical_services,
            color: AppColors.brown,
            title:
                '$_controlesSanitarios control${_controlesSanitarios != 1 ? 'es' : ''} sanitario${_controlesSanitarios != 1 ? 's' : ''}',
            sub: 'Registros de salud del ganado',
          ),
        );
      } else {
        _actividad.add(
          _ActividadItem(
            icon: Icons.medical_services,
            color: AppColors.brown,
            title: 'No hay controles sanitarios',
            sub: 'Registra el primer control',
          ),
        );
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado ──────────────────────────────
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panel de Control',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.green,
                        ),
                      ),
                      Text(
                        'Resumen de actividad ganadera',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.green),
                  tooltip: 'Actualizar dashboard',
                  onPressed: _cargarDatos,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              // ── Tarjetas de estadísticas ───────────────
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Total Animales',
                      value: '$_totalAnimales',
                      icon: Icons.pets,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Lotes Activos',
                      value: '$_totalLotes',
                      icon: Icons.grid_view,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Peso Promedio',
                      value: _pesoPromedio > 0
                          ? '${_pesoPromedio.toStringAsFixed(1)} kg'
                          : '— kg',
                      icon: Icons.monitor_weight,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Controles Sanitarios',
                      value: '$_controlesSanitarios',
                      icon: Icons.medical_services,
                      color: AppColors.brown,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Gráficas ───────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barras: peso por lote
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
                            child: _loteStats.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Sin datos',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY:
                                          (_loteStats
                                                      .map((e) => e.promedio)
                                                      .reduce(
                                                        (a, b) => a > b ? a : b,
                                                      ) *
                                                  1.3)
                                              .ceilToDouble(),
                                      barGroups: _loteStats
                                          .asMap()
                                          .entries
                                          .map(
                                            (e) => BarChartGroupData(
                                              x: e.key,
                                              barRods: [
                                                BarChartRodData(
                                                  toY: e.value.promedio,
                                                  color: AppColors.green,
                                                  width: 28,
                                                  borderRadius:
                                                      const BorderRadius.vertical(
                                                        top: Radius.circular(4),
                                                      ),
                                                ),
                                              ],
                                            ),
                                          )
                                          .toList(),
                                      titlesData: FlTitlesData(
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (v, _) {
                                              final i = v.toInt();
                                              if (i < 0 ||
                                                  i >= _loteStats.length) {
                                                return const SizedBox();
                                              }
                                              final nombre =
                                                  _loteStats[i].nombre;
                                              return Text(
                                                nombre.length > 8
                                                    ? '${nombre.substring(0, 7)}…'
                                                    : nombre,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
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
                                              style: const TextStyle(
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                      ),
                                      gridData: const FlGridData(
                                        drawVerticalLine: false,
                                      ),
                                      borderData: FlBorderData(show: false),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Pie: distribución por raza
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
                            child: _razaStats.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Sin datos',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : PieChart(
                                    PieChartData(
                                      sections: _razaStats
                                          .map(
                                            (r) => PieChartSectionData(
                                              value: r.cantidad.toDouble(),
                                              color: r.color,
                                              title:
                                                  '${r.raza}\n${r.porcentaje.toStringAsFixed(0)}%',
                                              titleStyle: TextStyle(
                                                fontSize: 10,
                                                color: r.color,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              titlePositionPercentageOffset:
                                                  1.4,
                                              radius: 60,
                                            ),
                                          )
                                          .toList(),
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

              // ── Actividad reciente ─────────────────────
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._actividad.map(
                      (a) => _activityItem(a.icon, a.color, a.title, a.sub),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Acciones rápidas ───────────────────────
            const Text(
              'Acciones Rápidas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.add,
                    label: 'Registrar Animal',
                    color: AppColors.green,
                    onTap: () => widget.onQuickAction(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.monitor_weight,
                    label: 'Registrar Peso',
                    color: AppColors.green,
                    onTap: () => widget.onQuickAction(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.grid_view,
                    label: 'Gestionar Lotes',
                    color: AppColors.blue,
                    onTap: () => widget.onQuickAction(1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.bar_chart,
                    label: 'Ver Reportes',
                    color: AppColors.brown,
                    onTap: () => widget.onQuickAction(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

// ── Modelos internos ──────────────────────────────────
class _LoteStat {
  final String nombre;
  final double promedio;
  _LoteStat({required this.nombre, required this.promedio});
}

class _RazaStat {
  final String raza;
  final int cantidad;
  final double porcentaje;
  final Color color;
  _RazaStat({
    required this.raza,
    required this.cantidad,
    required this.porcentaje,
    required this.color,
  });
}

class _ActividadItem {
  final IconData icon;
  final Color color;
  final String title;
  final String sub;
  _ActividadItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.sub,
  });
}
