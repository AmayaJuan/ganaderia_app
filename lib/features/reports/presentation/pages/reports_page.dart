import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Reportes con gráfico y resumen (como en el prototipo).
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  int _selectedReport = 0;
  int _selectedPeriod = 1; // Mes

  static const _periods = ['Semana', 'Mes', 'Trimestre', 'Año'];

  static const _lotes = [
    ('Lote Norte', 420.0, 1),
    ('Lote Sur', 375.0, 1),
    ('Lote Este', 342.0, 1),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reportes',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Análisis y estadísticas del ganado',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _reportCard(
                index: 0,
                title: 'Reporte de Peso',
                subtitle: 'Análisis de peso promedio por lote',
                icon: Icons.bar_chart,
              ),
              const SizedBox(width: 12),
              _reportCard(
                index: 1,
                title: 'Reporte Sanitario',
                subtitle: 'Vacunas y tratamientos aplicados',
                icon: Icons.medical_services_outlined,
              ),
              const SizedBox(width: 12),
              _reportCard(
                index: 2,
                title: 'Inventario General',
                subtitle: 'Distribución de animales por raza y lote',
                icon: Icons.picture_as_pdf_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                  'Período',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Últimos 30 días',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(_periods.length, (i) {
                    final active = _selectedPeriod == i;
                    return Padding(
                      padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                      child: ChoiceChip(
                        label: Text(_periods[i]),
                        selected: active,
                        onSelected: (_) =>
                            setState(() => _selectedPeriod = i),
                        selectedColor: AppColors.green,
                        labelStyle: TextStyle(
                          color: active ? Colors.white : Colors.black87,
                          fontSize: 12,
                        ),
                        backgroundColor: Colors.grey.shade100,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
                  'Peso Promedio por Lote',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Peso (kg)',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 600,
                      barGroups: List.generate(
                        _lotes.length,
                        (i) => BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: _lotes[i].$2,
                              color: AppColors.green,
                              width: 48,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= _lotes.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _lotes[i].$1,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 150,
                            reservedSize: 36,
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
          const SizedBox(height: 16),
          Row(
            children: _lotes
                .map(
                  (l) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: l.$1 != _lotes.last.$1 ? 12 : 0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE6E6E6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.$1,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${l.$2.toInt()} kg',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${l.$3} animales',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _reportCard({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final active = _selectedReport == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedReport = index),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: active ? AppColors.green : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? AppColors.green : const Color(0xFFE6E6E6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: active ? Colors.white : AppColors.green,
                size: 28,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: active ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: active ? Colors.white70 : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
