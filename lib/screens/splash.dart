import 'dart:async';
import 'package:beranibicara/screens/complete_profile.dart';
import 'package:beranibicara/screens/dashboard_student.dart';
import 'package:beranibicara/screens/dashboard_teacher.dart';
import 'package:beranibicara/screens/dashboard_admin.dart';
import 'package:beranibicara/screens/welcome.dart';
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
        final profile = await supabase
            .from('profiles')
            .select('role, kelas_id') // Ambil peran dan id kelas
            .eq('id', session.user.id)
            .single();

        if (!mounted) return;

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
      } catch (error) {
        // Jika gagal mengambil data profil, anggap sesi tidak valid
        await supabase.auth.signOut();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    } else {
      // Jika tidak ada sesi (pengguna belum login), arahkan ke halaman welcome
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI untuk splash screen ini hanya loading indicator
    // karena tugas utamanya adalah logika redirect di latar belakang.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}