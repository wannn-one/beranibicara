import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/cache/hive_service.dart';
import 'package:beranibicara/core/theme/app_theme.dart';
import 'package:beranibicara/injection.dart';
import 'package:beranibicara/routes/app_router.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/notifications/presentation/widgets/fcm_binder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive cache
  await HiveService.init();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: Injection.providers,
      child: Builder(
        builder: (context) {
          final authNotifier = context.read<AuthNotifier>();
          _router ??= AppRouter(authNotifier).router;

          return MaterialApp.router(
            title: 'Berani Bicara',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            builder: (context, child) {
              return FcmBinder(child: child ?? const SizedBox.shrink());
            },
          );
        },
      ),
    );
  }
}
