import 'package:flutter/material.dart';

class RekapPresensi extends StatelessWidget {
  const RekapPresensi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('Halaman Rekap Presensi'),
      ),
      body: const Center(
        child: Text('Rekap Presensi'),
      ),
    );
  }
}
