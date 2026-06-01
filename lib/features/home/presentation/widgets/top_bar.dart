import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class TopBar extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onTapWifi;

  const TopBar({
    super.key,
    required this.isOnline,
    required this.onTapWifi,
  });

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
              color: AppColors.green,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onTapWifi,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isOnline ? AppColors.greenLight : AppColors.redLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    isOnline ? Icons.wifi : Icons.wifi_off,
                    size: 16,
                    color: isOnline ? AppColors.green : AppColors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOnline ? 'En línea' : 'Sin conexión',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isOnline ? AppColors.green : AppColors.red,
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
