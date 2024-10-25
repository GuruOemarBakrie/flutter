import 'package:flutter/material.dart';

class KasKelasPage extends StatelessWidget {
  const KasKelasPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kas Kelas'),
      ),
      body: const Center(
        child: Text('Ini adalah halaman Kas Kelas'),
      ),
    );
  }
}
