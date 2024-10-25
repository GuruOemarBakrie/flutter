import 'package:flutter/material.dart';

class AsesmenSikapPage extends StatelessWidget {
  // Adding key parameter to the constructor
  const AsesmenSikapPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asesmen Sikap'),
      ),
      body: const Center(
        child: Text('Ini adalah halaman Asesmen Sikap'),
      ),
    );
  }
}
