import 'dart:async';
import 'package:flutter/material.dart';
import 'package:beranibicara/screens/welcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:beranibicara/screens/dashboard_student.dart';
import 'package:beranibicara/screens/complete_profile.dart';

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
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final session = supabase.auth.currentSession;

    if (session != null) {
      // Pengguna sudah login, sekarang cek profilnya
      try {
        final profile = await supabase
            .from('profiles')
            .select('kelas_id')
            .eq('id', session.user.id)
            .single();

        if (!mounted) return;

        if (profile['kelas_id'] == null) {
          // Jika kelas_id kosong, paksa isi profil
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
          );
        } else {
          // Jika kelas_id sudah ada, langsung ke Dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } catch (error) {
        // Jika ada error (misal profil belum ada), anggap sebagai pengguna baru
         Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    } else {
      // Pengguna belum login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/images/background.png",
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.white.withValues(alpha: 0.8),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Image.asset(
                    "assets/images/logo.png",
                    width: 500,
                    height: 300,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Welcome",
                  style: TextStyle(
                    fontFamily: 'LilyScriptOne',
                    fontSize: 45,
                    color: Color(0xFF3C83A8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}