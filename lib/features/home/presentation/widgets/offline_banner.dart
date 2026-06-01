import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class OfflineBanner extends StatelessWidget {
  final bool simulated;

  const OfflineBanner({super.key, this.simulated = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.brown,
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
