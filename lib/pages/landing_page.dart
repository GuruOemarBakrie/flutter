import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test_flutter/models/asessment_model.dart';
import 'package:test_flutter/services/auth_service.dart';

class AssessmentPage extends StatefulWidget {
  final int sesiUjianId;
  final int userId;
  final int rombelId;
  final int mataPelajaranId;

  const AssessmentPage({
    super.key,
    required this.sesiUjianId,
    required this.userId,
    required this.rombelId,
    required this.mataPelajaranId,
  });
  @override
  AssessmentPageState createState() => AssessmentPageState();
}

class AssessmentPageState extends State<AssessmentPage> {
  final AuthService _authService = AuthService();
  late PageController _pageController;
  Assessment? _assessment;
  final Map<int, Set<int>> _selectedAnswers = {};
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isLoading = true;
  String? _error;
  bool _isSidebarOpen = true;
  bool _isLandscape = false;
  int _currentPageIndex = 0; // Add this property
  // Screen size breakpoints
  static const double kTabletBreakpoint = 768.0;
  static const double kDesktopBreakpoint = 1024.0;
  bool get _isLargeScreen =>
      MediaQuery.of(context).size.width >= kTabletBreakpoint;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initialize();
    _pageController.addListener(_handlePageChange);
    // Update sidebar state based on screen size
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isSidebarOpen = _isLargeScreen;
      });
    });
  }

  void _handlePageChange() {
    if (_pageController.hasClients) {
      final currentPage = _pageController.page?.round() ?? 0;
      if (_currentPageIndex != currentPage) {
        setState(() {
          _currentPageIndex = currentPage;
        });
      }
    }
  }

  bool get _isMobileView =>
      MediaQuery.of(context).size.width < kTabletBreakpoint;

  // Responsive padding calculation
  EdgeInsets get _responsivePadding {
    final width = MediaQuery.of(context).size.width;
    if (width >= kDesktopBreakpoint) {
      return const EdgeInsets.all(32.0);
    } else if (width >= kTabletBreakpoint) {
      return const EdgeInsets.all(24.0);
    }
    return const EdgeInsets.all(16.0);
  }

  Future<void> _initialize() async {
    await _fetchAssessment();
    if (_assessment != null) {
      _enforceFullScreen();
      _startTimer();
    }
  }

  Future<void> _fetchAssessment() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await http.post(
        Uri.parse('${_authService.baseUrl}/get-assessment'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'sesi_ujian_id': widget.sesiUjianId,
          'user_id': widget.userId,
          'rombel_id': widget.rombelId,
          'matapelajaran_id': widget.mataPelajaranId,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['assessments'] != null && data['soal'] != null) {
          setState(() {
            _assessment = Assessment.fromJson(
              data['assessments'] as Map<String, dynamic>,
              data['soal'] as List<dynamic>,
            );
            _remainingTime = Duration(minutes: _assessment!.alokasiWaktu);
            _isLoading = false;
          });
        } else {
          throw Exception('Format data tidak sesuai');
        }
      } else {
        throw Exception('Gagal memuat data asesmen');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _enforceFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _toggleOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
      if (_isLandscape) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        } else {
          _timer?.cancel(); // Cancel timer first
          _autoSubmitAndExit(); // Call auto submit when time is up
        }
      });
    });
  }

  Future<void> _autoSubmitAndExit() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Waktu habis. Menyimpan jawaban...'),
              ],
            ),
          ),
        ),
      );

      final response = await http.post(
        Uri.parse('${_authService.baseUrl}/submit-assessment'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'sesi_ujian_id': widget.sesiUjianId,
          'user_id': widget.userId,
          'answers': _selectedAnswers
              .map((key, value) => MapEntry(key.toString(), value.toList())),
          'remaining_seconds': 0, // Time is up, so remaining seconds is 0
          'is_auto_submit': true, // Add flag to indicate auto submission
        }),
      );

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        // Show success message and exit after delay
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Waktu Habis'),
            content: const Text(
              'Waktu pengerjaan telah habis. '
              'Jawaban Anda telah disimpan secara otomatis.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );

        // Exit assessment page
        if (!mounted) return;
        Navigator.of(context).pop();
      } else {
        // Show error dialog and retry option
        if (!mounted) return;
        final shouldRetry = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text(
              'Gagal menyimpan jawaban. '
              'Apakah Anda ingin mencoba lagi?',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        );

        if (shouldRetry == true) {
          _autoSubmitAndExit(); // Retry submission
        }
      }
    } catch (e) {
      if (!mounted) return;
      // Show error dialog and retry option
      final shouldRetry = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(
            'Terjadi kesalahan: ${e.toString()}\n'
            'Apakah Anda ingin mencoba lagi?',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );

      if (shouldRetry == true) {
        _autoSubmitAndExit(); // Retry submission
      }
    }
  }

  Future<void> _submitAssessment() async {
    try {
      // Check if time is already up
      if (_remainingTime.inSeconds <= 0) {
        return; // Don't allow manual submission if time is up
      }

      // Check if all questions are answered
      if (!_areAllQuestionsAnswered()) {
        final unansweredCount =
            _assessment!.questions.length - _selectedAnswers.keys.length;

        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Peringatan'),
            content: Text(
              'Anda masih memiliki $unansweredCount soal yang belum dijawab. '
              'Anda hanya dapat mengumpulkan jawaban jika semua soal telah dijawab '
              'atau waktu telah habis.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final token = await _authService.getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final remainingSeconds = _remainingTime.inSeconds;

      final response = await http.post(
        Uri.parse('${_authService.baseUrl}/submit-assessment'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'sesi_ujian_id': widget.sesiUjianId,
          'user_id': widget.userId,
          'answers': _selectedAnswers
              .map((key, value) => MapEntry(key.toString(), value.toList())),
          'remaining_seconds': remainingSeconds,
          'is_auto_submit': false, // Add flag to indicate manual submission
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Show success message
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sukses'),
            content: const Text('Jawaban berhasil disimpan'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        if (!mounted) return;
        Navigator.of(context).pop(); // Exit assessment page
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan jawaban'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handlePopScope(bool didPop) async {
    if (didPop) return;

    // If time is up, don't allow manual exit
    if (_remainingTime.inSeconds <= 0) {
      return;
    }

    // Check if all questions are answered
    if (!_areAllQuestionsAnswered()) {
      final unansweredCount =
          _assessment!.questions.length - _selectedAnswers.keys.length;

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Peringatan'),
          content: Text(
            'Anda masih memiliki $unansweredCount soal yang belum dijawab. '
            'Anda hanya dapat keluar jika semua soal telah dijawab '
            'atau waktu telah habis.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari assessment? '
          'Jawaban Anda akan disimpan otomatis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _submitAssessment();
              if (!context.mounted) return;
              Navigator.of(context).pop(true);
            },
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );

    if (shouldPop ?? false) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
    }
  }

  // Helper method to check if all questions are answered
  bool _areAllQuestionsAnswered() {
    if (_assessment == null) return false;
    return _assessment!.questions.every((question) {
      final answers = _selectedAnswers[question.id];
      return answers != null && answers.isNotEmpty;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  void _handleAnswer(int questionId, int answerId, String jenisPg) {
    setState(() {
      if (!_selectedAnswers.containsKey(questionId)) {
        _selectedAnswers[questionId] = {};
      }

      if (jenisPg == 'Pilihan Ganda') {
        _selectedAnswers[questionId] = {answerId};
      } else if (jenisPg == 'Pilihan Ganda Kompleks') {
        if (_selectedAnswers[questionId]!.contains(answerId)) {
          _selectedAnswers[questionId]!.remove(answerId);
        } else {
          _selectedAnswers[questionId]!.add(answerId);
        }
      }
    });
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size(double.infinity, 48),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Konfirmasi Pengumpulan'),
              content:
                  const Text('Apakah Anda yakin ingin mengumpulkan jawaban?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _submitAssessment();
                  },
                  child: const Text('Ya, Kumpulkan'),
                ),
              ],
            ),
          );
        },
        child: const Text(
          'Kumpulkan',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildQuestionPage(int index) {
    final question = _assessment!.questions[index];
    return SingleChildScrollView(
      padding: _responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (question.bahanBacaan != null && question.bahanBacaan!.isNotEmpty)
            _buildBahanBacaanCard(question),
          const SizedBox(height: 16),
          _buildQuestionCard(question, index),
          const SizedBox(height: 16),
          _buildChoicesCard(question),
          const SizedBox(height: 24),
          _buildNavigationButtons(index),
        ],
      ),
    );
  }

  Widget _buildBahanBacaanCard(Question question) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bahan Bacaan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              question.bahanBacaan!,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Question question, int index) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: _responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Soal ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${question.jenisPg})',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              question.steamSoal,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionGrid() {
    if (_assessment == null) return const SizedBox.shrink();

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _assessment?.questions.length ?? 0,
      itemBuilder: (context, index) {
        final questionNumber = index + 1;
        final questionId = _assessment!.questions[index].id;
        final isAnswered = _selectedAnswers.containsKey(questionId) &&
            _selectedAnswers[questionId]!.isNotEmpty;
        final isCurrentPage = index == _currentPageIndex;

        return Material(
          elevation: isCurrentPage ? 4 : 1,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () {
              setState(() {
                _currentPageIndex = index;
              });
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              if (_isMobileView) {
                setState(() => _isSidebarOpen = false);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: isCurrentPage
                    ? Colors.blue[100]
                    : (isAnswered ? Colors.green[100] : Colors.grey[200]),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrentPage
                      ? Colors.blue
                      : (isAnswered ? Colors.green : Colors.grey[300]!),
                  width: isCurrentPage ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  questionNumber.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        isCurrentPage ? FontWeight.bold : FontWeight.normal,
                    color: isCurrentPage
                        ? Colors.blue[900]
                        : (isAnswered ? Colors.green[900] : Colors.grey[800]),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChoicesCard(Question question) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilihan Jawaban',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...question.choices.map((choice) {
              bool isSelected = _selectedAnswers.containsKey(question.id) &&
                  _selectedAnswers[question.id]!.contains(choice.id);
              return InkWell(
                onTap: () => _handleAnswer(
                  question.id,
                  choice.id,
                  question.jenisPg,
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[50] : Colors.white,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        question.jenisPg == 'Pilihan Ganda'
                            ? (isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked)
                            : (isSelected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank),
                        color: isSelected ? Colors.blue : Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          choice.text,
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                isSelected ? Colors.blue[900] : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(int currentIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (currentIndex > 0)
          ElevatedButton.icon(
            onPressed: () => _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Sebelumnya'),
          )
        else
          const SizedBox(),
        if (currentIndex < (_assessment?.questions.length ?? 0) - 1)
          ElevatedButton.icon(
            onPressed: () => _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Selanjutnya'),
          )
        else
          ElevatedButton.icon(
            onPressed: _submitAssessment,
            icon: const Icon(Icons.check),
            label: const Text('Simpan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
      ],
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
                _initialize();
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return _buildErrorScreen();
    }

    if (_assessment == null) {
      return const Scaffold(
        body: Center(
          child: Text('Tidak ada data assessment'),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: _handlePopScope,
      child: Scaffold(
        body: Stack(
          children: [
            _buildMainContent(),
            if (_isSidebarOpen)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () {}, // Prevent tap through
                  child: Row(
                    children: [
                      _buildResponsiveSidebar(),
                      if (_isMobileView)
                        GestureDetector(
                          onTap: () => setState(() => _isSidebarOpen = false),
                          child: Container(
                            width: MediaQuery.of(context).size.width -
                                (_isMobileView ? 280 : 320),
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_assessment == null) return const SizedBox.shrink();

    return Column(
      children: [
        AppBar(
          // Only show menu button on mobile
          leading: !_isLargeScreen
              ? IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => setState(() => _isSidebarOpen = true),
                )
              : null,
          title: Text(_assessment?.namaAsesmen ?? 'Assessment'),
          actions: [
            IconButton(
              icon: Icon(_isLandscape
                  ? Icons.stay_current_portrait
                  : Icons.stay_current_landscape),
              onPressed: _toggleOrientation,
            ),
            // Only show timer in header on mobile or when sidebar is closed
            if (!_isLargeScreen || !_isSidebarOpen)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    _formatDuration(_remainingTime),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Expanded(
          child: Row(
            children: [
              // Show sidebar directly in the layout for large screens
              if (_isLargeScreen) _buildResponsiveSidebar(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index;
                    });
                  },
                  itemCount: _assessment!.questions.length,
                  itemBuilder: (context, index) => _buildQuestionPage(index),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Modify _buildResponsiveSidebar to handle large screens
  Widget _buildResponsiveSidebar() {
    return Container(
      width: _isLargeScreen ? 320 : 280,
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[800],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_remainingTime),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // Only show close button on mobile
                    if (!_isLargeScreen)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => _isSidebarOpen = false),
                      ),
                  ],
                ),
                const Text(
                  'Waktu Tersisa',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildQuestionGrid(),
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }
}
