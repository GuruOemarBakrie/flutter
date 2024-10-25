import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  // Adding key parameter to the constructor
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('About'),
      ),
      body: const Center(
        child: Text('Ini adalah halaman About'),
      ),
    );
  }
}
