import 'package:flutter/material.dart';

class GanaderiaLogo extends StatelessWidget {
  const GanaderiaLogo({super.key, this.size = 90});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF20A67A),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.agriculture,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}