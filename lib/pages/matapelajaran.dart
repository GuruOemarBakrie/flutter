import 'package:flutter/material.dart';

class MataPelajaranPage extends StatelessWidget {
  const MataPelajaranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mata Pelajaran'),
      ),
      body: const Center(
        child: Text('Ini adalah halaman Mata Pelajaran'),
      ),
    );
  }
}
