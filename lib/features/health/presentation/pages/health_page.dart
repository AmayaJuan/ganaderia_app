import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class HealthPage extends StatelessWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final historial = [
      {
        'tipo': 'Vacunación',
        'animal': 'Brahman #1',
        'descripcion': 'Fiebre Aftosa',
        'fecha': '11/5/2024',
        'proximo': '11/11/2024',
        'estado': 'Completado',
      },
      {
        'tipo': 'Tratamiento',
        'animal': 'Cebú #2',
        'descripcion': 'Antibiótico',
        'fecha': '10/5/2024',
        'proximo': '17/5/2024',
        'estado': 'Pendiente',
      },
      {
        'tipo': 'Vacunación',
        'animal': 'Angus #3',
        'descripcion': 'Brucelosis',
        'fecha': '5/5/2024',
        'proximo': '5/11/2024',
        'estado': 'Pendiente',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Control Sanitario',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.green,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gestión de vacunas y tratamientos',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Registro'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stat cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.vaccines,
                  iconColor: AppColors.green,
                  label: 'Total Vacunas',
                  value: '23',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.medical_services,
                  iconColor: Colors.blue,
                  label: 'Tratamientos',
                  value: '12',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.warning_amber,
                  iconColor: const Color(0xFF9A6A00),
                  label: 'Próximos',
                  value: '5',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Banner controles próximos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF3DC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE7D5A0)),
            ),
            child: Row(
              children: const [
                Icon(Icons.warning_amber, color: Color(0xFF9A6A00)),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Controles Próximos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9A6A00),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Hay 2 vacunaciones programadas para los próximos 7 días',
                        style: TextStyle(color: Color(0xFF9A6A00), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tabla historial sanitario
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Historial Sanitario',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                    columns: const [
                      DataColumn(label: Text('Tipo',           style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Animal',         style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Descripción',    style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Fecha',          style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Próximo Control',style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Estado',         style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: historial.map((item) {
                      final completado = item['estado'] == 'Completado';
                      return DataRow(cells: [
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item['tipo']!,
                              style: TextStyle(
                                color: AppColors.green,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(item['animal']!)),
                        DataCell(Text(item['descripcion']!)),
                        DataCell(Text(item['fecha']!)),
                        DataCell(Text(item['proximo']!)),
                        DataCell(
                          Text(
                            item['estado']!,
                            style: TextStyle(
                              color: completado ? AppColors.green : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para las stat cards
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}