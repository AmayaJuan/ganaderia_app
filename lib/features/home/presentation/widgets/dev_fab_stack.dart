import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Botones flotantes de desarrollo (como en el prototipo).
class DevFabStack extends StatelessWidget {
  const DevFabStack({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _fab(
          label: 'Test Datos',
          color: AppColors.brown,
          icon: Icons.science_outlined,
          onPressed: () {},
        ),
        const SizedBox(height: 8),
        _fab(
          label: 'Cargar Datos de Prueba',
          color: AppColors.green,
          icon: Icons.sync,
          onPressed: () {},
        ),
        const SizedBox(height: 8),
        _fab(
          label: 'Debug',
          color: AppColors.blue,
          icon: Icons.bug_report_outlined,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _fab({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton.extended(
      heroTag: label,
      onPressed: onPressed,
      backgroundColor: color,
      foregroundColor: Colors.white,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
