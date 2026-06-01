import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Vista de reportes (cuerpo dentro del home).
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

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
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.green,
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
              _reportCard(
                title: 'Reporte de Peso',
                subtitle: 'Analisis de peso promedio por lote',
                active: true,
              ),
              const SizedBox(width: 12),
              _reportCard(
                title: 'Reporte Sanitario',
                subtitle: 'Vacunas y tratamientos aplicados',
                active: false,
              ),
              const SizedBox(width: 12),
              _reportCard(
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

  Widget _reportCard({
    required String title,
    required String subtitle,
    required bool active,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: active ? AppColors.green : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6E6E6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.insert_chart_outlined,
              color: active ? Colors.white : AppColors.green,
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
}
