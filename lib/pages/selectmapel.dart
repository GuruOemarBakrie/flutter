import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test_flutter/services/auth_service.dart';
import 'dashboardmapel.dart';

class SelectMapel extends StatefulWidget {
  const SelectMapel({super.key});

  @override
  State<SelectMapel> createState() => _SelectMapelState();
}

class _SelectMapelState extends State<SelectMapel> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _mapelList = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _debugInfo;

  @override
  void initState() {
    super.initState();
    _fetchMapelList();
  }

  Future<void> _fetchMapelList() async {
    try {
      final token = await _authService.getToken();
      final userData = await _authService.getUserData();
      final userId = userData?['id'];

      if (token == null || userId == null) {
        throw Exception('Token atau User ID tidak ditemukan');
      }

      final response = await http.post(
        Uri.parse('${_authService.baseUrl}/selectmapel'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id':
              int.parse(userId.toString()), // Pastikan user_id adalah integer
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['mata_pelajaran'] != null) {
          setState(() {
            _mapelList =
                List<Map<String, dynamic>>.from(responseData['mata_pelajaran']);
            _debugInfo = responseData['debug_info'];
            _isLoading = false;
          });
        } else {
          throw Exception('Format data tidak sesuai');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Gagal memuat mata pelajaran');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onMapelSelected(
      BuildContext context, Map<String, dynamic> mapel) async {
    try {
      final token = await _authService.getToken();
      final userData = await _authService.getUserData();
      final userId = userData?['id'];

      if (token == null || userId == null) {
        throw Exception('Token atau User ID tidak ditemukan');
      }

      if (!mounted) return;

      final payload = {
        'user_id':
            int.parse(userId.toString()), // Pastikan user_id adalah integer
        'matapelajaran_id': mapel['id'],
        'rombel_id': _debugInfo?['rombel_id'],
        'tahunpelajaran_id': _debugInfo?['tahun_pelajaran']?['id'],
        'semester': _debugInfo?['semester'],
      };

      // Pastikan semua nilai adalah tipe yang diharapkan
      payload.forEach((key, value) {
        if (value == null) {
          throw Exception('Nilai $key tidak boleh null');
        }
        if (key != 'semester' && value is! int) {
          throw Exception('Nilai $key harus berupa integer');
        }
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardMapel(
            mapelData: mapel,
            additionalData: payload,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Mata Pelajaran'),
        backgroundColor: Colors.blue[800],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            ElevatedButton(
              onPressed: _fetchMapelList,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_mapelList.isEmpty) {
      return const Center(
        child: Text('Tidak ada mata pelajaran tersedia'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1.0,
        ),
        itemCount: _mapelList.length,
        itemBuilder: (context, index) {
          return _buildMapelCard(_mapelList[index]);
        },
      ),
    );
  }

  Widget _buildMapelCard(Map<String, dynamic> mapel) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () => _onMapelSelected(context, mapel),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Colors.blue[300]!, Colors.blue[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.book,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    mapel['nama_mapel'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (mapel['rumpun'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    mapel['rumpun'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
