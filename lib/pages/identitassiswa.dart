import 'package:flutter/material.dart';

class IdentitasSiswa extends StatelessWidget {
  const IdentitasSiswa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('Identitas Diri'),
      ),
      body: const Center(
        child: Text('profil'),
      ),
    );
  }
}
