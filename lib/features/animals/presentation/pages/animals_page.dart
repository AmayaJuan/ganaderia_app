import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Vista de registro de animales (cuerpo dentro del home).
class AnimalsPage extends StatelessWidget {
  const AnimalsPage({super.key});

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
                      color: AppColors.green,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
