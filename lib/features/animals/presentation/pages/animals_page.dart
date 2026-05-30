import 'package:flutter/material.dart';

class AnimalsPage extends StatelessWidget {
  const AnimalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animales')),
      body: const Center(child: Text('Animales — próximamente')),
    );
  }
}