import 'package:beranibicara/screens/student/dashboard_student.dart';
import 'package:beranibicara/screens/student/create_report.dart';
import 'package:beranibicara/screens/student/profile.dart';
import 'package:beranibicara/screens/student/track_report.dart';
import 'package:beranibicara/screens/student/track_reports_list.dart';
import 'package:beranibicara/screens/student/socialization_list.dart';
import 'package:beranibicara/screens/student/mading_kelas.dart';
import 'package:beranibicara/screens/splash.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class StudentDrawer extends StatefulWidget {
  // Variabel untuk menerima rute halaman saat ini
  final String currentRoute;

  const StudentDrawer({super.key, required this.currentRoute});

  @override
  State<StudentDrawer> createState() => _StudentDrawerState();
}

class _StudentDrawerState extends State<StudentDrawer> {
  String? _userName;
  String? _userEmail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void didUpdateWidget(StudentDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data ketika widget diupdate (misalnya setelah kembali dari profil)
    if (oldWidget.currentRoute != widget.currentRoute) {
      _fetchUserProfile();
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        final response = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', currentUser.id)
            .single();

        if (mounted) {
          setState(() {
            _userName = response['full_name'] ?? 'Siswa';
            _userEmail = currentUser.email ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _userName = supabase.auth.currentUser?.userMetadata?['full_name'] ?? 'Siswa';
          _userEmail = supabase.auth.currentUser?.email ?? '';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Refresh data setiap kali drawer dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchUserProfile();
      }
    });

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF36A395),
            ),
            child: GestureDetector(
              onTap: () {
                // Jika sudah di halaman profil, tutup saja drawer-nya
                if (widget.currentRoute == StudentProfileScreen.routeName) {
                  Navigator.pop(context);
                  return;
                }
                // Navigasi ke halaman profil
                Navigator.pop(context); // Tutup drawer dulu
                Navigator.pushReplacementNamed(context, StudentProfileScreen.routeName);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Icon(Icons.person, size: 36),
                  ),
                  const SizedBox(height: 8),
                  _isLoading
                      ? Container(
                          width: 120,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                      : Text(
                          _userName ?? 'Siswa',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                  const SizedBox(height: 2),
                  _isLoading
                      ? Container(
                          width: 160,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                      : Text(
                          _userEmail ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded),
            title: const Text('Dashboard'),
            // Logika untuk highlight: jika rute saat ini adalah rute dashboard
            selected: widget.currentRoute == StudentDashboardScreen.routeName,
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              // Ganti halaman, jangan menumpuk
              Navigator.pushReplacementNamed(context, StudentDashboardScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_box_rounded),
            title: const Text('Buat Laporan'),
            // Logika untuk highlight: jika rute saat ini adalah rute create report
            selected: widget.currentRoute == CreateReportScreen.routeName,
            onTap: () {
              Navigator.pop(context);
              if (widget.currentRoute != CreateReportScreen.routeName) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateReportScreen()),
                );
              }
            },
          ),
          // ListTile untuk Tracking Laporan
          ListTile(
            leading: const Icon(Icons.track_changes_rounded),
            title: const Text('Tracking Laporan'),
            // Logika untuk highlight: jika rute saat ini adalah rute tracking reports list
            selected: widget.currentRoute == TrackReportsListScreen.routeName || widget.currentRoute == TrackingReportScreen.routeName,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, TrackReportsListScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.article_rounded),
            title: const Text('Sosialisasi & Edukasi'),
            selected: widget.currentRoute == SocializationListScreen.routeName,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, SocializationListScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.forum_rounded),
            title: const Text('Mading Kelas'),
            selected: widget.currentRoute == MadingKelasScreen.routeName,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, MadingKelasScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: const Text('Profil'),
            selected: widget.currentRoute == StudentProfileScreen.routeName,
            onTap: () {
              Navigator.pop(context);
              if (widget.currentRoute != StudentProfileScreen.routeName) {
                Navigator.pushReplacementNamed(context, StudentProfileScreen.routeName);
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Logout'),
            onTap: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SplashScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
