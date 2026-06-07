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

  int _totalAnimales = 0;
  int _totalLotes = 0;
  double _pesoPromedio = 0;
  int _controlesSanitarios = 0;
  List<_LoteStat> _loteStats = [];
  List<_RazaStat> _razaStats = [];
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
      final animalesData = await _db
          .from('animales')
          .select('id, raza, id_lote, registro_peso(peso, fecha)');
      final lotesData = await _db.from('lotes').select('id, nombre');
      final sanitariosData =
          await _db.from('registro_sanitario').select('id');

      final animales = animalesData as List;
      final lotes = lotesData as List;
      final sanitarios = sanitariosData as List;

      _totalAnimales = animales.length;
      _totalLotes = lotes.length;
      _controlesSanitarios = sanitarios.length;

      // Peso promedio global
      final todosLosPesos = <double>[];
      for (final a in animales) {
        final pesos = a['registro_peso'] as List?;
        if (pesos != null && pesos.isNotEmpty) {
          pesos.sort((x, y) =>
              (y['fecha'] as String).compareTo(x['fecha'] as String));
          todosLosPesos.add((pesos.first['peso'] as num).toDouble());
        }
      }
      _pesoPromedio = todosLosPesos.isEmpty
          ? 0
          : todosLosPesos.reduce((a, b) => a + b) / todosLosPesos.length;

      // Peso por lote
      final loteNombres = <String, String>{
        for (final l in lotes) l['id'] as String: l['nombre'] as String,
      };
      final pesosPorLote = <String, List<double>>{};
      for (final a in animales) {
        final idLote = a['id_lote'] as String?;
        if (idLote == null) continue;
        final pesos = a['registro_peso'] as List?;
        if (pesos == null || pesos.isEmpty) continue;
        pesos.sort((x, y) =>
            (y['fecha'] as String).compareTo(x['fecha'] as String));
        final ultimo = (pesos.first['peso'] as num).toDouble();
        pesosPorLote.putIfAbsent(idLote, () => []).add(ultimo);
      }
      _loteStats = pesosPorLote.entries.map((e) {
        final avg = e.value.reduce((a, b) => a + b) / e.value.length;
        return _LoteStat(
          nombre: loteNombres[e.key] ?? e.key.substring(0, 6),
          promedio: avg,
        );
      }).toList()
        ..sort((a, b) => b.promedio.compareTo(a.promedio));

      // Distribución por raza
      final razaCount = <String, int>{};
      for (final a in animales) {
        final raza = (a['raza'] as String?)?.trim() ?? 'Otra';
        razaCount[raza] = (razaCount[raza] ?? 0) + 1;
      }
      final colors = [
        AppColors.green, AppColors.blue, AppColors.brown,
        Colors.orange, Colors.purple, Colors.teal,
      ];
      int ci = 0;
      _razaStats = razaCount.entries.map((e) {
        final color = colors[ci++ % colors.length];
        return _RazaStat(
          raza: e.key,
          cantidad: e.value,
          porcentaje: animales.isEmpty
              ? 0
              : (e.value / animales.length * 100).roundToDouble(),
          color: color,
        );
      }).toList()
        ..sort((a, b) => b.cantidad.compareTo(a.cantidad));

      // Actividad reciente
      _actividad = [
        _ActividadItem(
          icon: Icons.agriculture,
          color: AppColors.green,
          title: animales.isEmpty
              ? 'No hay animales registrados'
              : '$_totalAnimales animal${_totalAnimales != 1 ? 'es' : ''} registrado${_totalAnimales != 1 ? 's' : ''}',
          sub: animales.isEmpty
              ? 'Registra tu primer animal'
              : 'Último ingreso en el sistema',
        ),
        _ActividadItem(
          icon: Icons.grid_view,
          color: AppColors.blue,
          title: lotes.isEmpty
              ? 'No hay lotes creados'
              : '$_totalLotes lote${_totalLotes != 1 ? 's' : ''} activo${_totalLotes != 1 ? 's' : ''}',
          sub: lotes.isEmpty
              ? 'Crea tu primer lote'
              : 'Áreas de pastoreo configuradas',
        ),
        _ActividadItem(
          icon: Icons.medical_services,
          color: AppColors.brown,
          title: sanitarios.isEmpty
              ? 'No hay controles sanitarios'
              : '$_controlesSanitarios control${_controlesSanitarios != 1 ? 'es' : ''} sanitario${_controlesSanitarios != 1 ? 's' : ''}',
          sub: sanitarios.isEmpty
              ? 'Registra el primer control'
              : 'Registros de salud del ganado',
        ),
      ];

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
            // Encabezado
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Panel de Control',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.green)),
                      Text('Resumen de actividad ganadera',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.green),
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
              // Tarjetas stats — responsive
              LayoutBuilder(builder: (ctx, constraints) {
                final isMobile = constraints.maxWidth < 600;
                if (isMobile) {
                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      StatCard(label: 'Total Animales', value: '$_totalAnimales', icon: Icons.agriculture, color: AppColors.green),
                      StatCard(label: 'Lotes Activos', value: '$_totalLotes', icon: Icons.grid_view, color: AppColors.blue),
                      StatCard(label: 'Peso Promedio', value: _pesoPromedio > 0 ? '${_pesoPromedio.toStringAsFixed(1)} kg' : '— kg', icon: Icons.monitor_weight, color: AppColors.green),
                      StatCard(label: 'Controles Sanitarios', value: '$_controlesSanitarios', icon: Icons.medical_services, color: AppColors.brown),
                    ],
                  );
                }
                return Row(children: [
                  Expanded(child: StatCard(label: 'Total Animales', value: '$_totalAnimales', icon: Icons.agriculture, color: AppColors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: StatCard(label: 'Lotes Activos', value: '$_totalLotes', icon: Icons.grid_view, color: AppColors.blue)),
                  const SizedBox(width: 12),
                  Expanded(child: StatCard(label: 'Peso Promedio', value: _pesoPromedio > 0 ? '${_pesoPromedio.toStringAsFixed(1)} kg' : '— kg', icon: Icons.monitor_weight, color: AppColors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: StatCard(label: 'Controles Sanitarios', value: '$_controlesSanitarios', icon: Icons.medical_services, color: AppColors.brown)),
                ]);
              }),
              const SizedBox(height: 20),

              // Gráficas — responsive
              LayoutBuilder(builder: (ctx, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final barras = _buildBarras();
                final pie = _buildPie();
                if (isMobile) {
                  return Column(children: [
                    barras,
                    const SizedBox(height: 12),
                    pie,
                  ]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: barras),
                    const SizedBox(width: 12),
                    Expanded(child: pie),
                  ],
                );
              }),
              const SizedBox(height: 20),

              // Actividad reciente
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Actividad Reciente',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    ..._actividad.map(
                        (a) => _activityItem(a.icon, a.color, a.title, a.sub)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Acciones rápidas
            const Text('Acciones Rápidas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (ctx, constraints) {
              final isMobile = constraints.maxWidth < 500;
              if (isMobile) {
                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    QuickActionButton(icon: Icons.add, label: 'Registrar Animal', color: AppColors.green, onTap: () => widget.onQuickAction(2)),
                    QuickActionButton(icon: Icons.monitor_weight, label: 'Registrar Peso', color: AppColors.green, onTap: () => widget.onQuickAction(3)),
                    QuickActionButton(icon: Icons.grid_view, label: 'Gestionar Lotes', color: AppColors.blue, onTap: () => widget.onQuickAction(1)),
                    QuickActionButton(icon: Icons.bar_chart, label: 'Ver Reportes', color: AppColors.brown, onTap: () => widget.onQuickAction(4)),
                  ],
                );
              }
              return Row(children: [
                Expanded(child: QuickActionButton(icon: Icons.add, label: 'Registrar Animal', color: AppColors.green, onTap: () => widget.onQuickAction(2))),
                const SizedBox(width: 10),
                Expanded(child: QuickActionButton(icon: Icons.monitor_weight, label: 'Registrar Peso', color: AppColors.green, onTap: () => widget.onQuickAction(3))),
                const SizedBox(width: 10),
                Expanded(child: QuickActionButton(icon: Icons.grid_view, label: 'Gestionar Lotes', color: AppColors.blue, onTap: () => widget.onQuickAction(1))),
                const SizedBox(width: 10),
                Expanded(child: QuickActionButton(icon: Icons.bar_chart, label: 'Ver Reportes', color: AppColors.brown, onTap: () => widget.onQuickAction(4))),
              ]);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBarras() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Peso Promedio por Lote',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: _loteStats.isEmpty
              ? const Center(child: Text('Sin datos', style: TextStyle(color: Colors.grey)))
              : BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (_loteStats.map((e) => e.promedio).reduce((a, b) => a > b ? a : b) * 1.3).ceilToDouble(),
                  barGroups: _loteStats.asMap().entries.map((e) =>
                    BarChartGroupData(x: e.key, barRods: [
                      BarChartRodData(toY: e.value.promedio, color: AppColors.green, width: 28,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                    ])).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= _loteStats.length) return const SizedBox();
                        final n = _loteStats[i].nombre;
                        return Text(n.length > 8 ? '${n.substring(0, 7)}…' : n,
                            style: const TextStyle(fontSize: 10));
                      })),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 150,
                        getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)))),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                )),
        ),
      ]),
    );
  }

  Widget _buildPie() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Distribución por Raza',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: _razaStats.isEmpty
              ? const Center(child: Text('Sin datos', style: TextStyle(color: Colors.grey)))
              : PieChart(PieChartData(
                  sections: _razaStats.map((r) => PieChartSectionData(
                    value: r.cantidad.toDouble(), color: r.color,
                    title: '${r.raza}\n${r.porcentaje.toStringAsFixed(0)}%',
                    titleStyle: TextStyle(fontSize: 10, color: r.color, fontWeight: FontWeight.bold),
                    titlePositionPercentageOffset: 1.4, radius: 60,
                  )).toList(),
                  sectionsSpace: 2, centerSpaceRadius: 30,
                )),
        ),
      ]),
    );
  }

  Widget _activityItem(IconData icon, Color color, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        )),
      ]),
    );
  }
}

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
  _RazaStat({required this.raza, required this.cantidad, required this.porcentaje, required this.color});
}

class _ActividadItem {
  final IconData icon;
  final Color color;
  final String title;
  final String sub;
  _ActividadItem({required this.icon, required this.color, required this.title, required this.sub});
}