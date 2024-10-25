import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test_flutter/services/auth_service.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:test_flutter/pages/selecttest_page.dart';

class DashboardMapel extends StatefulWidget {
  final Map<String, dynamic> mapelData;
  final Map<String, dynamic> additionalData;

  const DashboardMapel({
    super.key,
    required this.mapelData,
    required this.additionalData,
  });
  @override
  State<DashboardMapel> createState() => _DashboardMapelState();
}

class _DashboardMapelState extends State<DashboardMapel> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _dashboardData = {};

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  void _initializeDashboard() {
    setState(() {
      _dashboardData = {
        'mapel': widget.mapelData,
        'additional': widget.additionalData,
        'performance': {
          'attendance': 90,
          'assignments': 85,
          'quizzes': 78,
        },
        'recentActivities': [
          {'title': 'Quiz 1 submitted', 'date': '2024-10-10', 'type': 'quiz'},
          {
            'title': 'Assignment 2 due',
            'date': '2024-10-15',
            'type': 'assignment'
          },
          {
            'title': 'Chapter 3 reading',
            'date': '2024-10-18',
            'type': 'material'
          },
        ],
        'upcomingSchedule': [
          {'title': 'Live Session', 'date': '2024-10-20', 'time': '10:00 AM'},
          {
            'title': 'Group Project Deadline',
            'date': '2024-10-25',
            'time': '11:59 PM'
          },
        ],
        'announcements': [
          {'title': 'New course material available', 'date': '2024-10-08'},
          {'title': 'Midterm exam schedule', 'date': '2024-10-05'},
        ],
      };
    });
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http.post(
        Uri.parse('${_authService.baseUrl}/dashboardmapel'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(widget.additionalData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _dashboardData = {
            ..._dashboardData,
            ...responseData,
          };
          _isLoading = false;
        });
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(
            errorData['error'] as String? ?? 'Gagal memuat data dashboard');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.mapelData['nama_mapel'] as String? ?? 'Dashboard Mapel'),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDashboardData,
          ),
        ],
      ),
      body: _buildResponsiveBody(),
    );
  }

  Widget _buildResponsiveBody() {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (MediaQuery.of(context).size.width > 1200) {
          return _buildDesktopLayout();
        } else if (MediaQuery.of(context).size.width > 600) {
          return _buildTabletLayout(orientation);
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildScrollableContent(_buildMainContent()),
        ),
        Expanded(
          flex: 1,
          child: _buildScrollableContent(_buildSidebar()),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(Orientation orientation) {
    return orientation == Orientation.landscape
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildScrollableContent(_buildMainContent()),
              ),
              Expanded(
                flex: 2,
                child: _buildScrollableContent(_buildSidebar()),
              ),
            ],
          )
        : _buildMobileLayout();
  }

  Widget _buildMobileLayout() {
    return _buildScrollableContent(
      Column(
        children: [
          _buildMainContent(),
          _buildSidebar(),
        ],
      ),
    );
  }

  Widget _buildScrollableContent(Widget content) {
    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: content,
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 20),
          _buildPerformanceChart(),
          const SizedBox(height: 20),
          _buildMenuGrid(),
          const SizedBox(height: 20),
          _buildRecentActivities(),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Error: $_error',
                  style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildUpcomingSchedule(),
          const SizedBox(height: 20),
          _buildAnnouncements(),
          const SizedBox(height: 20),
          _buildQuickLinks(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dashboardData['siswa']?['nama'] as String? ??
                  'Nama Peserta Didik',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kelas: ${_dashboardData['rombel']?['nama_rombel'] as String? ?? 'Tidak Tersedia'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Semester: ${_dashboardData['tahun_pelajaran']?['semester'] as String? ?? 'Tidak Tersedia'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Tahun Pelajaran: ${_dashboardData['tahun_pelajaran']?['tahun'] as String? ?? 'Tidak Tersedia'}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    final performanceData = [
      PerformanceData('Kehadiran',
          _dashboardData['performance']?['attendance'] as int? ?? 0),
      PerformanceData(
          'Tugas', _dashboardData['performance']?['assignments'] as int? ?? 0),
      PerformanceData(
          'Kuis', _dashboardData['performance']?['quizzes'] as int? ?? 0),
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ikhtisar Kinerja',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${performanceData[groupIndex].category}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: '${rod.toY.round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              performanceData[value.toInt()].category,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value % 20 == 0) {
                            return Text(
                              '${value.toInt()}%',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.black.withOpacity(0.4)),
                      left: BorderSide(color: Colors.black.withOpacity(0.4)),
                    ),
                  ),
                  barGroups: performanceData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          color: Colors.blue,
                          width: 25,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid() {
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Presensi',
        'icon': Icons.checklist,
        'color': Colors.green,
        // 'route': '/presensi'
      },
      {
        'title': 'Materi',
        'icon': Icons.book,
        'color': Colors.blue,
        // 'route': '/materi'
      },
      {
        'title': 'Tugas',
        'icon': Icons.assignment,
        'color': Colors.orange,
        // 'route': '/tugas'
      },
      {
        'title': 'Asesmen',
        'icon': Icons.assignment_turned_in,
        'color': Colors.purple,
        // 'route': '/asesmen'
      },
      {
        'title': 'Ruang Test',
        'icon': Icons.edit,
        'color': Colors.orangeAccent,
        'route': '/ruang-test'
      },
      {
        'title': 'Refleksi',
        'icon': Icons.lightbulb_outline,
        'color': Colors.amber,
        // 'route': '/refleksi'
      },
    ];

    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: menuItems.map((item) => _buildMenuItem(item)).toList(),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    return StaggeredGridTile.fit(
      crossAxisCellCount: 1,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            _navigateToPage(item['route'] as String);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item['icon'] as IconData,
                    size: 48, color: item['color'] as Color),
                const SizedBox(height: 8),
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToPage(String route) {
    final Map<String, dynamic> arguments = {
      'rombel_id': widget.additionalData['rombel_id'],
      'matapelajaran_id': widget.mapelData['id'],
      'user_id': widget.additionalData['user_id'],
      'tahunpelajaran_id':
          widget.additionalData['tahunpelajaran_id'], // Tambahkan ini
    };

    if (route == '/ruang-test') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RuangTestPage(
            userId: arguments['user_id'] as int,
            matapelajaranId: arguments['matapelajaran_id'] as int,
            rombelId: arguments['rombel_id'] as int,
            tahunPelajaranId:
                arguments['tahunpelajaran_id'] as int, // Tambahkan ini
          ),
        ),
      );
    } else {
      Navigator.of(context).pushNamed(
        route,
        arguments: arguments,
      );
    }
  }

  Widget _buildRecentActivities() {
    final activities =
        _dashboardData['recentActivities'] as List<dynamic>? ?? [];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aktivitas Terbaru',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index] as Map<String, dynamic>;
                return ListTile(
                  title: Text(activity['title'] as String),
                  subtitle: Text(_formatDate(activity['date'] as String)),
                  leading: _getActivityIcon(activity['type'] as String),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSchedule() {
    final schedule = _dashboardData['upcomingSchedule'] as List<dynamic>? ?? [];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jadwal Mendatang',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: schedule.length,
              itemBuilder: (context, index) {
                final event = schedule[index] as Map<String, dynamic>;
                return ListTile(
                  title: Text(event['title'] as String),
                  subtitle: Text(
                      '${_formatDate(event['date'] as String)} ${event['time']}'),
                  leading: const Icon(Icons.event, color: Colors.blue),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncements() {
    final announcements =
        _dashboardData['announcements'] as List<dynamic>? ?? [];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengumuman',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement =
                    announcements[index] as Map<String, dynamic>;
                return ListTile(
                  title: Text(announcement['title'] as String),
                  subtitle: Text(_formatDate(announcement['date'] as String)),
                  leading: const Icon(Icons.announcement, color: Colors.red),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinks() {
    final List<Map<String, dynamic>> quickLinks = [
      {'title': 'Silabus', 'icon': Icons.description, 'route': '/silabus'},
      {'title': 'Jadwal', 'icon': Icons.calendar_today, 'route': '/jadwal'},
      {'title': 'Diskusi', 'icon': Icons.forum, 'route': '/diskusi'},
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tautan Cepat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...quickLinks.map((link) => ListTile(
                  title: Text(link['title'] as String),
                  leading: Icon(link['icon'] as IconData, color: Colors.blue),
                  onTap: () => _navigateToPage(link['route'] as String),
                )),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('d MMMM yyyy').format(date);
  }

  Icon _getActivityIcon(String type) {
    switch (type) {
      case 'quiz':
        return const Icon(Icons.quiz, color: Colors.orange);
      case 'assignment':
        return const Icon(Icons.assignment, color: Colors.green);
      case 'material':
        return const Icon(Icons.book, color: Colors.blue);
      default:
        return const Icon(Icons.circle, color: Colors.grey);
    }
  }
}

class PerformanceData {
  final String category;
  final int value;

  PerformanceData(this.category, this.value);
}
