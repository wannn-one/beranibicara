import 'dart:async';
import 'package:beranibicara/screens/admin/dashboard_admin.dart';
import 'package:beranibicara/screens/admin/kelola_laporan.dart';
import 'package:beranibicara/screens/admin/kelola_user.dart';
import 'package:beranibicara/screens/admin/profile.dart';
import 'package:beranibicara/screens/student/dashboard_student.dart';
import 'package:beranibicara/screens/student/create_report.dart';
import 'package:beranibicara/screens/student/profile.dart';
import 'package:beranibicara/screens/student/track_report.dart';
import 'package:beranibicara/screens/student/track_reports_list.dart';
import 'package:beranibicara/screens/student/socialization_list.dart';
import 'package:beranibicara/screens/admin/kelola_konten.dart';
import 'package:beranibicara/screens/teacher/dashboard_teacher.dart';
import 'package:beranibicara/screens/teacher/student_list_screen.dart';
import 'package:beranibicara/screens/teacher/report_list_screen.dart';
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
        ManageContentScreen.routeName: (context) => const ManageContentScreen(),
        AdminProfileScreen.routeName: (context) => const AdminProfileScreen(),
        StudentDashboardScreen.routeName: (context) => const StudentDashboardScreen(),
        StudentProfileScreen.routeName: (context) => const StudentProfileScreen(),
        CreateReportScreen.routeName: (context) => const CreateReportScreen(),
        TrackReportsListScreen.routeName: (context) => const TrackReportsListScreen(),
        SocializationListScreen.routeName: (context) => const SocializationListScreen(),
        TeacherDashboardScreen.routeName: (context) => const TeacherDashboardScreen(),
        TeacherStudentListScreen.routeName: (context) => const TeacherStudentListScreen(),
        TeacherReportListScreen.routeName: (context) => const TeacherReportListScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == TrackingReportScreen.routeName) {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null && args['reportId'] != null) {
            return MaterialPageRoute(
              builder: (context) => TrackingReportScreen(reportId: args['reportId']),
            );
          }
        }
        return null;
      },

    );
  }
}