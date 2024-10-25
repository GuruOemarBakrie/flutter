import 'package:flutter/material.dart';
import 'package:test_flutter/pages/server_config_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Oemar Bakrie',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home:
          const ServerConfigPage(), // Mengubah halaman awal ke ServerConfigPage
      debugShowCheckedModeBanner: false,
    );
  }
}
