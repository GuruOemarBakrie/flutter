import 'package:flutter/material.dart';

class PresensiPage extends StatelessWidget {
  const PresensiPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi'),
      ),
      body: const Center(
        child: Text('Ini adalah halaman Presensi'),
      ),
    );
  }
}
