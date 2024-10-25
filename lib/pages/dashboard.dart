import 'package:flutter/material.dart';
import 'package:test_flutter/services/auth_service.dart';
import 'package:test_flutter/pages/login_page.dart';

// Import your page files here
import 'identitassiswa.dart';
import 'selectmapel.dart';
import 'asesmen_sikap_page.dart';
import 'presensi_page.dart';
import 'kas_kelas_page.dart';
import 'about_page.dart';

class Dashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const Dashboard({super.key, required this.userData});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final AuthService _authService = AuthService();
  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Profil', 'icon': Icons.person},
    {'title': 'Mata Pelajaran', 'icon': Icons.book},
    {'title': 'Asesmen Sikap', 'icon': Icons.assessment},
    {'title': 'Presensi', 'icon': Icons.check_circle},
    {'title': 'Kas Kelas', 'icon': Icons.money},
    {'title': 'About', 'icon': Icons.info},
  ];

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Halaman Utama'),
        backgroundColor: Colors.blue[800],
      ),
      drawer: _buildDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header dengan informasi pengguna
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[800],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.userData['name'] ?? 'Pengguna'}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 6.0,
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.userData['email'] ?? 'email@example.com'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            // Grid view card besar
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      return _buildMenuCard(_menuItems[index]);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(Map<String, dynamic> item) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _navigateToPage(item['title']);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item['icon'], size: 40, color: Colors.blue[800]),
            const SizedBox(height: 8),
            Text(
              item['title'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue[800],
                shadows: [
                  Shadow(
                    blurRadius: 4.0,
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPage(String title) {
    switch (title) {
      case 'Profil':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const IdentitasSiswa(),
          ),
        );
        break;
      case 'Mata Pelajaran':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SelectMapel(),
          ),
        );
        break;
      case 'Asesmen Sikap':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AsesmenSikapPage(),
          ),
        );
        break;
      case 'Presensi':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PresensiPage(),
          ),
        );
        break;
      case 'Kas Kelas':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const KasKelasPage(),
          ),
        );
        break;
      case 'About':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AboutPage(),
          ),
        );
        break;
      default:
        // Handle unknown pages
        break;
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(widget.userData['name'] ?? 'Nama Pengguna'),
            accountEmail: Text(widget.userData['email'] ?? 'email@example.com'),
            currentAccountPicture: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/logoOB.png'),
            ),
            decoration: BoxDecoration(
              color: Colors.blue[800],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          _buildListTile(
            context,
            title: 'Profil',
            icon: Icons.person,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const IdentitasSiswa(),
                ),
              );
            },
          ),
          _buildListTile(
            context,
            title: 'Halaman Rekap Presensi',
            icon: Icons.list,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PresensiPage(),
                ),
              );
            },
          ),
          _buildListTile(
            context,
            title: 'Keluar',
            icon: Icons.exit_to_app,
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Konfirmasi"),
                    content: const Text("Apakah Anda yakin ingin keluar?"),
                    actions: <Widget>[
                      TextButton(
                        child: const Text("Batal"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text("Ya"),
                        onPressed: () {
                          Navigator.of(context).pop(); // Tutup dialog
                          _logout(); // Panggil fungsi logout
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      leading: Icon(icon),
      onTap: onTap,
    );
  }
}
