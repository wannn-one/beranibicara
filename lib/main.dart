import 'dart:async';
import 'package:flutter/foundation.dart';
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
import 'package:beranibicara/screens/student/mading_kelas.dart';
import 'package:beranibicara/screens/admin/kelola_konten.dart';
import 'package:beranibicara/screens/admin/kelola_nisn.dart';
import 'package:beranibicara/screens/admin/mading_kelas_admin.dart';
import 'package:beranibicara/screens/teacher/mading_kelas_teacher.dart';
import 'package:beranibicara/screens/teacher/dashboard_teacher.dart';
import 'package:beranibicara/screens/teacher/student_list_screen.dart';
import 'package:beranibicara/screens/teacher/report_list_screen.dart';
import 'package:beranibicara/screens/splash.dart';
import 'package:beranibicara/screens/auth/update_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/services/fcm_service.dart';
import 'package:intl/date_symbol_data_local.dart';

// Kunci global untuk mengakses Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Load .env first (required)
  await dotenv.load(fileName: ".env");
  
  // ✅ Initialize Supabase (required)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  // ✅ Setup auth listener (required)
  _setupAuthListener();
  
  // ✅ Start app immediately
  runApp(const MyApp());
  
  // ✅ Initialize heavy services in background
  _initializeBackgroundServices();
}

// ✅ Background initialization
void _initializeBackgroundServices() async {
  try {
    // Initialize locale data in background
    await initializeDateFormatting('id_ID', null);
    
    // Initialize FCM in background
    await FCMService.initialize();
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing background services: $e');
    }
  }
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
      // User login, initialize FCM setelah delay untuk menunggu profile dibuat
      Future.delayed(const Duration(seconds: 3), () {
        FCMService.initialize();
      });
      
      // Kita arahkan ke SplashScreen, biarkan router pintar kita yang bekerja
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SplashScreen()),
        (route) => false,
      );
    } else if (event == AuthChangeEvent.signedOut) {
      // User logout, delete FCM token
      FCMService.deleteTokenFromDatabase();
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
        KelolaNISNScreen.routeName: (context) => const KelolaNISNScreen(),
        AdminProfileScreen.routeName: (context) => const AdminProfileScreen(),
        StudentDashboardScreen.routeName: (context) => const StudentDashboardScreen(),
        StudentProfileScreen.routeName: (context) => const StudentProfileScreen(),
        CreateReportScreen.routeName: (context) => const CreateReportScreen(),
        TrackReportsListScreen.routeName: (context) => const TrackReportsListScreen(),
        SocializationListScreen.routeName: (context) => const SocializationListScreen(),
        MadingKelasScreen.routeName: (context) => const MadingKelasScreen(),
        MadingKelasAdminScreen.routeName: (context) => const MadingKelasAdminScreen(),
        MadingKelasTeacherScreen.routeName: (context) => const MadingKelasTeacherScreen(),
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