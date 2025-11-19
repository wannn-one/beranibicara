import 'dart:async';
import 'package:beranibicara/screens/auth/complete_profile.dart';
import 'package:beranibicara/screens/student/dashboard_student.dart';
import 'package:beranibicara/screens/teacher/dashboard_teacher.dart';
import 'package:beranibicara/screens/admin/dashboard_admin.dart';
import 'package:beranibicara/screens/welcome.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Instance Supabase
final supabase = Supabase.instance.client;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Memanggil fungsi redirect saat halaman ini pertama kali dimuat
    _redirect();
  }

  Future<void> _redirect() async {
    // Memberi jeda sesaat agar frame pertama selesai di-build
    // dan menghindari error transisi yang terlalu cepat.
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final session = supabase.auth.currentSession;

    if (session != null) {
      // Jika ada sesi (pengguna sudah login), periksa profilnya
      try {
        // ✅ Add timeout untuk database query
        final profile = await supabase
            .from('profiles')
            .select('role, kelas_id') // Ambil peran dan id kelas
            .eq('id', session.user.id)
            .single()
            .timeout(const Duration(seconds: 5)); // ✅ Timeout 5 detik

        if (!mounted) return;

        // ✅ Navigate immediately after getting data
        _navigateBasedOnRole(profile);
        
      } catch (error) {
        // ✅ Handle timeout/error gracefully
        if (kDebugMode) {
          print('Error loading profile: $error');
        }
        
        // Jika gagal mengambil data profil, anggap sesi tidak valid
        supabase.auth.signOut();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    } else {
      // Jika tidak ada sesi (pengguna belum login), arahkan ke halaman welcome
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  // ✅ Extract navigation logic
  void _navigateBasedOnRole(Map<String, dynamic> profile) {
    final userRole = profile['role'];

    // Jika user adalah siswa dan belum melengkapi profil (kelas_id masih kosong)
    if (userRole == 'siswa' && profile['kelas_id'] == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
      );
      return; // Hentikan eksekusi lebih lanjut
    }

    // Jika profil sudah lengkap, arahkan berdasarkan peran
    switch (userRole) {
      case 'siswa':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const StudentDashboardScreen()),
        );
        break;
      case 'guru':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TeacherDashboardScreen()),
        );
        break;
      case 'tppk':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
        );
        break;
      default:
        // Jika peran tidak dikenali, arahkan ke halaman welcome
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Better loading indicator with progress
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo atau icon aplikasi
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.security,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Memuat aplikasi...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Berani Bicara',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}