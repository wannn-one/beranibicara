import 'dart:async';
import 'package:beranibicara/screens/admin/dashboard_admin.dart';
import 'package:beranibicara/screens/admin/kelola_laporan.dart';
import 'package:beranibicara/screens/admin/kelola_user.dart';
import 'package:beranibicara/screens/splash.dart';
import 'package:beranibicara/screens/auth/update_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Kunci global untuk mengakses Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Setup listener di sini, di tempat yang selalu aktif
  _setupAuthListener();

  runApp(const MyApp());
}

void _setupAuthListener() {
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final AuthChangeEvent event = data.event;
    
    // Jika event-nya adalah password recovery...
    if (event == AuthChangeEvent.passwordRecovery) {
      // Gunakan GlobalKey untuk navigasi
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (context) => const UpdatePasswordScreen()),
      );
    } else if (event == AuthChangeEvent.signedIn) {
      // Kita arahkan ke SplashScreen, biarkan router pintar kita yang bekerja
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SplashScreen()),
        (route) => false,
      );
    }
  });
}


final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Pasang GlobalKey ke MaterialApp
      navigatorKey: navigatorKey,
      title: 'Berani Bicara',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'LeagueSpartan', // Menggunakan LeagueSpartan sebagai default
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // Rute awal adalah SplashScreen
      routes: {
        '/': (context) => const SplashScreen(),
        AdminDashboardScreen.routeName: (context) => const AdminDashboardScreen(),
        ManageReportsScreen.routeName: (context) => const ManageReportsScreen(),
        ManageUsersScreen.routeName: (context) => const ManageUsersScreen(),
      },

    );
  }
}