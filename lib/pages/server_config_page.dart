import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_flutter/pages/login_page.dart';

class ServerConfigPage extends StatefulWidget {
  const ServerConfigPage({super.key});

  @override
  State<ServerConfigPage> createState() => _ServerConfigPageState();
}

class _ServerConfigPageState extends State<ServerConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  bool _isLoading = false;
  bool _isLocalServer =
      false; // Toggle untuk switch antara web dan local server

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverUrlController.text =
          prefs.getString('server_url') ?? 'http://192.168.1.2:8080';
      _isLocalServer = prefs.getBool('is_local_server') ?? true;
    });
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final prefs = await SharedPreferences.getInstance();
        String serverUrl = _serverUrlController.text.trim();

        // Handle URL format based on server type
        if (_isLocalServer) {
          // For local server, ensure it has http:// and port
          if (!serverUrl.startsWith('http://') &&
              !serverUrl.startsWith('https://')) {
            serverUrl = 'http://$serverUrl';
          }
          // Validate that port is included for local server
          final uri = Uri.parse(serverUrl);
          if (uri.port == 0) {
            throw Exception('Port harus ditentukan untuk server lokal');
          }
        } else {
          // For web server, ensure it has https:// (preferred for web)
          if (!serverUrl.startsWith('http://') &&
              !serverUrl.startsWith('https://')) {
            serverUrl = 'https://$serverUrl';
          }
          // Remove any port if accidentally included for web server
          final uri = Uri.parse(serverUrl);
          if (uri.port != 0 && uri.port != 80 && uri.port != 443) {
            serverUrl = '${uri.scheme}://${uri.host}';
          }
        }

        // Remove trailing slash if exists
        if (serverUrl.endsWith('/')) {
          serverUrl = serverUrl.substring(0, serverUrl.length - 1);
        }

        await prefs.setString('server_url', serverUrl);
        await prefs.setBool('is_local_server', _isLocalServer);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
      setState(() => _isLoading = false);
    }
  }

  String? _validateServerUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Alamat server tidak boleh kosong';
    }

    String url = value;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = _isLocalServer ? 'http://$url' : 'https://$url';
    }

    try {
      final uri = Uri.parse(url);

      if (_isLocalServer) {
        // Validasi untuk server lokal
        if (uri.port == 0) {
          return 'Port harus ditentukan untuk server lokal (contoh: 192.168.1.2:8080)';
        }

        // Validasi format IP (sederhana)
        if (!uri.host.contains('.') || uri.host.split('.').length != 4) {
          if (!uri.host.toLowerCase().contains('localhost')) {
            return 'Format IP tidak valid';
          }
        }
      } else {
        // Validasi untuk web server
        if (!uri.host.contains('.')) {
          return 'Format domain tidak valid';
        }
      }
    } catch (e) {
      return 'Format alamat tidak valid';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfigurasi Server'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Konfigurasi Server',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Switch untuk memilih tipe server
                      SwitchListTile(
                        title: Text(
                            _isLocalServer ? 'Server Lokal' : 'Server Web'),
                        subtitle: Text(
                          _isLocalServer
                              ? 'Gunakan IP dan Port (contoh: 192.168.1.2:8080)'
                              : 'Gunakan alamat web (contoh: www.omarbakri.com)',
                        ),
                        value: _isLocalServer,
                        onChanged: (bool value) {
                          setState(() {
                            _isLocalServer = value;
                            // Clear input when switching
                            _serverUrlController.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _serverUrlController,
                        decoration: InputDecoration(
                          labelText: 'Alamat Server',
                          hintText: _isLocalServer
                              ? '192.168.1.2:8080'
                              : 'www.omarbakri.com',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.computer),
                        ),
                        validator: _validateServerUrl,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLocalServer
                            ? 'Format: IP:PORT (contoh: 192.168.1.2:8080)'
                            : 'Format: Domain (contoh: www.omarbakri.com)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveConfig,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Simpan & Lanjutkan',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }
}
