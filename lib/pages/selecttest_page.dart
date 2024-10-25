// ruang_test_page.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test_flutter/services/auth_service.dart';
import 'package:test_flutter/pages/asessment.dart';

class RuangTestPage extends StatefulWidget {
  final int userId;
  final int matapelajaranId;
  final int rombelId;
  final int tahunPelajaranId;

  const RuangTestPage({
    super.key,
    required this.userId,
    required this.matapelajaranId,
    required this.rombelId,
    required this.tahunPelajaranId,
  });

  @override
  RuangTestPageState createState() => RuangTestPageState();
}

class RuangTestPageState extends State<RuangTestPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _assessments = [];
  Map<String, dynamic>? _studentInfo;

  @override
  void initState() {
    super.initState();
    _fetchAssessments();
  }

  Future<void> _fetchAssessments() async {
    setState(() => _isLoading = true);

    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final baseUrl = await AuthService.getBaseUrl();

      final response = await http.post(
        Uri.parse('$baseUrl/ruang-test'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': widget.userId,
          'matapelajaran_id': widget.matapelajaranId,
          'rombel_id': widget.rombelId,
          'tahunpelajaran_id': widget.tahunPelajaranId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _assessments =
                List<Map<String, dynamic>>.from(responseData['assessments']);
            _studentInfo = responseData['studentInfo'] as Map<String, dynamic>?;
            _isLoading = false;
          });
        }
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorData['error'] ?? 'Gagal memuat data asesmen');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startAssessment(int sesiUjianId, BuildContext context) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final baseUrl = await AuthService.getBaseUrl();

      final response = await http.post(
        Uri.parse('$baseUrl/start-assessment'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'sesi_ujian_id': sesiUjianId,
          'user_id': widget.userId,
          'rombel_id': widget.rombelId,
          'matapelajaran_id': widget.matapelajaranId,
        }),
      );

      if (!mounted) return;

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Successful start - proceed to assessment page
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => AssessmentPage(
              sesiUjianId: sesiUjianId,
              userId: widget.userId,
              rombelId: widget.rombelId,
              mataPelajaranId: widget.matapelajaranId,
            ),
          ),
        );

        // Refresh the assessments list after returning from AssessmentPage
        if (result == true) {
          await _fetchAssessments();
        }
      } else if (response.statusCode == 403) {
        // Show error message and prevent navigation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(responseData['error'] ?? 'Tidak dapat mengakses ujian'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );

        // Optional: Refresh the assessment list to update status
        await _fetchAssessments();
      } else {
        // Handle other errors
        _showErrorSnackBar(
            context, responseData['error'] ?? 'Gagal memulai asesmen');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(context, 'Error: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruang Test'),
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
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _fetchAssessments,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_studentInfo != null) _buildStudentInfo(),
        Expanded(
          child: _assessments.isEmpty
              ? _buildEmptyState()
              : _buildAssessmentGrid(),
        ),
      ],
    );
  }

  Widget _buildStudentInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _studentInfo!['nama'] ?? 'Nama tidak tersedia',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('NIS: ${_studentInfo!['nis'] ?? 'N/A'}'),
              const SizedBox(width: 16),
              Text('NISN: ${_studentInfo!['nisn'] ?? 'N/A'}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada asesmen tersedia',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _assessments.length,
      itemBuilder: (context, index) {
        final assessment = _assessments[index];
        return _buildAssessmentCard(assessment, context);
      },
    );
  }

  Widget _buildAssessmentCard(
      Map<String, dynamic> assessment, BuildContext context) {
    final bool isCompleted = assessment['status'] == 'completed';
    final bool isActive = assessment['statuskehadiran'] == 'Aktif';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color:
          isActive ? Colors.grey[200] : null, // Warna abu-abu untuk yang aktif
      child: InkWell(
        onTap: (isCompleted || isActive)
            ? null // Nonaktifkan tap jika completed atau aktif
            : () => _startAssessment(assessment['id'] as int, context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(isCompleted, isActive),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(isCompleted, isActive),
                  size: 32,
                  color: isCompleted || isActive ? Colors.grey : Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                assessment['namaasesmen'] ?? 'Asesmen Tidak Bernama',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCompleted || isActive ? Colors.grey : Colors.black,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '${assessment['jumlah_soal_pg']} Soal',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isCompleted || isActive ? Colors.grey : Colors.grey[600],
                ),
              ),
              if (isCompleted)
                Text(
                  'Selesai',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              if (isActive)
                Text(
                  'Sesi Aktif',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

// Helper methods untuk status card
  Color _getStatusColor(bool isCompleted, bool isActive) {
    if (isCompleted) return Colors.grey.shade100;
    if (isActive) return Colors.orange.shade100;
    return Colors.blue.shade100;
  }

  IconData _getStatusIcon(bool isCompleted, bool isActive) {
    if (isCompleted) return Icons.check_circle;
    if (isActive) return Icons.lock;
    return Icons.assignment;
  }
}
