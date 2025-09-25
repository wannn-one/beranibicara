import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/screens/splash.dart';
import 'package:beranibicara/screens/teacher/dashboard_teacher.dart';
import 'package:beranibicara/screens/teacher/student_list_screen.dart';
import 'package:beranibicara/screens/teacher/report_list_screen.dart';
import 'package:beranibicara/screens/student/socialization_list.dart';

final supabase = Supabase.instance.client;

class TeacherDrawer extends StatefulWidget {
  final String currentRoute;
  const TeacherDrawer({super.key, required this.currentRoute});

  @override
  State<TeacherDrawer> createState() => _TeacherDrawerState();
}

class _TeacherDrawerState extends State<TeacherDrawer> {
  String _teacherName = 'Guru';
  String _teacherEmail = '';
  String _className = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeacherInfo();
  }

  Future<void> _fetchTeacherInfo() async {
    try {
      final teacherId = supabase.auth.currentUser!.id;
      final currentUser = supabase.auth.currentUser;
      
      // Get teacher profile and class info
      final results = await Future.wait([
        supabase
            .from('profiles')
            .select('full_name')
            .eq('id', teacherId)
            .single(),
        supabase
            .from('kelas')
            .select('tingkat, jurusan')
            .eq('wali_kelas_id', teacherId)
            .maybeSingle(),
      ]);

      final profile = results[0] as Map<String, dynamic>;
      final kelas = results[1] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _teacherName = profile['full_name'] ?? 'Guru';
          _teacherEmail = currentUser?.email ?? '';
          _className = kelas != null ? 'Kelas ${kelas['tingkat']} ${kelas['jurusan']}' : '';
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _teacherName = supabase.auth.currentUser?.userMetadata?['full_name'] ?? 'Guru';
          _teacherEmail = supabase.auth.currentUser?.email ?? '';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF36A395),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Icon(Icons.school, size: 36, color: Color(0xFF36A395)),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoading ? 'Memuat...' : _teacherName,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 16, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                Text(
                  _teacherEmail,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                if (_className.isNotEmpty)
                  Text(
                    _className,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded),
            title: const Text('Dashboard'),
            selected: widget.currentRoute == TeacherDashboardScreen.routeName,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, TeacherDashboardScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_rounded),
            title: const Text('Daftar Siswa'),
            selected: widget.currentRoute == TeacherStudentListScreen.routeName,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, TeacherStudentListScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.report_rounded),
            title: const Text('Laporan Siswa'),
            selected: widget.currentRoute == TeacherReportListScreen.routeName,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, TeacherReportListScreen.routeName);
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Logout'),
            onTap: () async {
              try {
                await supabase.auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const SplashScreen()),
                    (route) => false,
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal logout: $error')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
} 