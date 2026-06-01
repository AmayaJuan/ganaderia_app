import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'action_button.dart';
import 'stat_card.dart';

class DashboardBody extends StatelessWidget {
  final ValueChanged<int> onQuickAction;

  const DashboardBody({super.key, required this.onQuickAction});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Panel de Control',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.green,
            ),
          ),
          const Text(
            'Resumen de actividad ganadera',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.green),
            ),
            child: const Row(
              children: [
                Icon(Icons.save, color: AppColors.green, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '📋 Guardado automático activado: '
                    'Todos tus registros se guardan localmente en tu '
                    'dispositivo y permanecen aunque cierres la aplicación.',
                    style: TextStyle(fontSize: 12, color: AppColors.green),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Total Animales',
                  value: '0',
                  icon: Icons.pets,
                  color: AppColors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Lotes Activos',
                  value: '0',
                  icon: Icons.grid_view,
                  color: AppColors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Peso Promedio',
                  value: '0 kg',
                  icon: Icons.monitor_weight,
                  color: AppColors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Controles Sanitarios',
                  value: '0',
                  icon: Icons.medical_services,
                  color: AppColors.brown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                            gridData:
                                const FlGridData(drawVerticalLine: false),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                                color: AppColors.green,
                                title: 'Brahman\n33%',
                                titleStyle: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.green,
                                ),
                                titlePositionPercentageOffset: 1.4,
                                radius: 60,
                              ),
                              PieChartSectionData(
                                value: 33,
                                color: AppColors.blue,
                                title: 'Cebú\n33%',
                                titleStyle: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.blue,
                                ),
                                titlePositionPercentageOffset: 1.4,
                                radius: 60,
                              ),
                              PieChartSectionData(
                                value: 33,
                                color: AppColors.brown,
                                title: 'Angus\n33%',
                                titleStyle: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.brown,
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
                  AppColors.green,
                  'No hay animales registrados',
                  'Registra tu primer animal',
                ),
                _activityItem(
                  Icons.grid_view,
                  AppColors.blue,
                  'No hay lotes creados',
                  'Crea tu primer lote',
                ),
                _activityItem(
                  Icons.medical_services,
                  AppColors.brown,
                  'No hay controles sanitarios',
                  'Registra el primer control',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
                  onTap: () => onQuickAction(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuickActionButton(
                  icon: Icons.monitor_weight,
                  label: 'Registrar Peso',
                  color: AppColors.green,
                  onTap: () => onQuickAction(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuickActionButton(
                  icon: Icons.grid_view,
                  label: 'Gestionar Lotes',
                  color: AppColors.blue,
                  onTap: () => onQuickAction(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuickActionButton(
                  icon: Icons.bar_chart,
                  label: 'Ver Reportes',
                  color: AppColors.brown,
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
          color: AppColors.green,
          width: 30,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _activityItem(
    IconData icon,
    Color color,
    String title,
    String sub,
  ) {
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
