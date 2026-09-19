import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';

import 'package:beranibicara/features/auth/presentation/screens/splash_screen.dart';
import 'package:beranibicara/features/auth/presentation/screens/welcome_screen.dart';
import 'package:beranibicara/features/auth/presentation/screens/login_screen.dart';
import 'package:beranibicara/features/auth/presentation/screens/register_screen.dart';
import 'package:beranibicara/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:beranibicara/features/auth/presentation/screens/update_password_screen.dart';
import 'package:beranibicara/features/auth/presentation/screens/complete_profile_screen.dart';
import 'package:beranibicara/features/auth/presentation/screens/profile_screen.dart';
import 'package:beranibicara/features/notifications/presentation/screens/notification_list_screen.dart';
import 'package:beranibicara/features/dashboard/presentation/screens/student_dashboard_screen.dart';
import 'package:beranibicara/features/dashboard/presentation/screens/teacher_dashboard_screen.dart';
import 'package:beranibicara/features/dashboard/presentation/screens/tppk_dashboard_screen.dart';
import 'package:beranibicara/features/dashboard/presentation/screens/admin_dashboard_screen.dart';

// Reports Screens
import 'package:beranibicara/features/reports/presentation/screens/report_list_screen.dart';
import 'package:beranibicara/features/reports/presentation/screens/create_report_screen.dart';
import 'package:beranibicara/features/reports/presentation/screens/edit_report_screen.dart';
import 'package:beranibicara/features/reports/presentation/screens/report_detail_screen.dart';
import 'package:beranibicara/features/admin/presentation/screens/user_management_screen.dart';
import 'package:beranibicara/features/admin/presentation/screens/kelas_management_screen.dart';
import 'package:beranibicara/features/admin/presentation/screens/admin_statistics_screen.dart';
import 'package:beranibicara/features/admin/presentation/screens/admin_settings_screen.dart';
import 'package:beranibicara/features/socialization/presentation/screens/socialization_list_screen.dart';
import 'package:beranibicara/features/socialization/presentation/screens/socialization_detail_screen.dart';
import 'package:beranibicara/features/socialization/presentation/screens/create_socialization_screen.dart';
import 'package:beranibicara/features/socialization/presentation/screens/edit_socialization_screen.dart';
import 'package:beranibicara/features/cerita_kelas/presentation/screens/cerita_kelas_list_screen.dart';
import 'package:beranibicara/features/cerita_kelas/presentation/screens/cerita_kelas_detail_screen.dart';
import 'package:beranibicara/features/cerita_kelas/presentation/screens/create_cerita_kelas_screen.dart';
import 'package:beranibicara/features/cerita_kelas/presentation/screens/edit_cerita_kelas_screen.dart';

/// App Router Configuration with go_router
class AppRouter {
  final AuthNotifier authNotifier;

  AppRouter(this.authNotifier);

  late final GoRouter router = GoRouter(
    initialLocation: AppConstants.routeSplash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuthenticated = authNotifier.isAuthenticated;
      final user = authNotifier.user;
      final currentPath = state.matchedLocation;

      if (authNotifier.isPasswordRecovery) {
        if (currentPath != AppConstants.routeUpdatePassword) {
          return AppConstants.routeUpdatePassword;
        }
        return null;
      }

      if (currentPath == AppConstants.routeUpdatePassword) {
        if (isAuthenticated && user != null) {
          return user.hasCompletedProfile
              ? AppConstants.routeDashboard
              : AppConstants.routeCompleteProfile;
        }
        return AppConstants.routeLogin;
      }

      // Public routes (no auth needed)
      final publicRoutes = [
        AppConstants.routeSplash,
        AppConstants.routeWelcome,
        AppConstants.routeLogin,
        AppConstants.routeRegister,
        AppConstants.routeForgotPassword,
      ];

      // If on public route
      if (publicRoutes.contains(currentPath)) {
        // If authenticated and has complete profile, redirect to dashboard
        if (isAuthenticated && user != null && user.hasCompletedProfile) {
          return AppConstants.routeDashboard;
        }
        // If authenticated but incomplete profile, go to complete profile
        if (isAuthenticated && user != null && !user.hasCompletedProfile) {
          return AppConstants.routeCompleteProfile;
        }
        // Otherwise, stay on public route
        return null;
      }

      // If trying to access protected route while unauthenticated
      if (!isAuthenticated) {
        return AppConstants.routeWelcome;
      }

      // If authenticated but profile incomplete (siswa without kelas)
      if (user != null && !user.hasCompletedProfile) {
        if (currentPath != AppConstants.routeCompleteProfile) {
          return AppConstants.routeCompleteProfile;
        }
      } else if (currentPath == AppConstants.routeCompleteProfile) {
        return AppConstants.routeDashboard;
      }

      // Allow access to protected route
      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: AppConstants.routeSplash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Welcome Screen
      GoRoute(
        path: AppConstants.routeWelcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Login Screen
      GoRoute(
        path: AppConstants.routeLogin,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Register Screen
      GoRoute(
        path: AppConstants.routeRegister,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Forgot Password Screen
      GoRoute(
        path: AppConstants.routeForgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      GoRoute(
        path: AppConstants.routeUpdatePassword,
        name: 'update-password',
        builder: (context, state) => const UpdatePasswordScreen(),
      ),

      // Complete Profile Screen
      GoRoute(
        path: AppConstants.routeCompleteProfile,
        name: 'complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),

      GoRoute(
        path: AppConstants.routeProfile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      GoRoute(
        path: AppConstants.routeNotifications,
        name: 'notifications',
        builder: (context, state) => const NotificationListScreen(),
      ),

      // Dashboard (role-based)
      GoRoute(
        path: AppConstants.routeDashboard,
        name: 'dashboard',
        builder: (context, state) {
          final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
          final user = authNotifier.user;

          if (user == null) {
            // Shouldn't happen due to redirect, but handle gracefully
            return const WelcomeScreen();
          }

          // Route to appropriate dashboard based on role
          switch (user.role) {
            case UserRole.siswa:
              return const StudentDashboardScreen();
            case UserRole.guru:
              return const DashboardTeacherScreen();
            case UserRole.tppk:
              return const DashboardTPPKScreen();
            case UserRole.admin:
              return const DashboardAdminScreen();
          }
        },
      ),

      // Profile Screen (future)
      // Reports, Socialization, Cerita Kelas routes will be added in Phase 2

      // ========================================================================
      // REPORTS ROUTES
      // ========================================================================

      // Reports List (accessible by all authenticated users, filtered by role)
      GoRoute(
        path: AppConstants.routeReports,
        name: 'reports',
        builder: (context, state) => const ReportListScreen(),
      ),

      // Create Report (students only)
      GoRoute(
        path: AppConstants.routeCreateReport,
        name: 'create-report',
        redirect: (context, state) {
          final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
          final user = authNotifier.user;
          
          // Only students can create reports
          if (user?.role != UserRole.siswa) {
            return AppConstants.routeDashboard;
          }
          return null;
        },
        builder: (context, state) => const CreateReportScreen(),
      ),

      GoRoute(
        path: AppConstants.routeEditReport,
        name: 'edit-report',
        redirect: (context, state) {
          final authNotifier =
              Provider.of<AuthNotifier>(context, listen: false);
          if (authNotifier.user?.role != UserRole.siswa) {
            return AppConstants.routeDashboard;
          }
          return null;
        },
        builder: (context, state) {
          final reportId = state.pathParameters['id'];
          if (reportId == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid Report ID')),
            );
          }
          return EditReportScreen(reportId: reportId);
        },
      ),

      // Report Detail (role-based access control in screen logic)
      GoRoute(
        path: AppConstants.routeReportDetail,
        name: 'report-detail',
        builder: (context, state) {
          final reportId = state.pathParameters['id'];
          if (reportId == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid Report ID')),
            );
          }
          return ReportDetailScreen(reportId: reportId);
        },
      ),

      GoRoute(
        path: AppConstants.routeAdminUsers,
        name: 'admin-users',
        redirect: (context, state) {
          final authNotifier =
              Provider.of<AuthNotifier>(context, listen: false);
          if (authNotifier.user?.role != UserRole.admin) {
            return AppConstants.routeDashboard;
          }
          return null;
        },
        builder: (context, state) => const UserManagementScreen(),
      ),

      GoRoute(
        path: AppConstants.routeAdminKelas,
        name: 'admin-kelas',
        redirect: (context, state) {
          final role =
              Provider.of<AuthNotifier>(context, listen: false).user?.role;
          if (role != UserRole.admin && role != UserRole.tppk) {
            return AppConstants.routeDashboard;
          }
          return null;
        },
        builder: (context, state) => const KelasManagementScreen(),
      ),

      GoRoute(
        path: AppConstants.routeAdminStats,
        name: 'admin-stats',
        redirect: (context, state) {
          final authNotifier =
              Provider.of<AuthNotifier>(context, listen: false);
          if (authNotifier.user?.role != UserRole.admin) {
            return AppConstants.routeDashboard;
          }
          return null;
        },
        builder: (context, state) => const AdminStatisticsScreen(),
      ),

      GoRoute(
        path: AppConstants.routeAdminSettings,
        name: 'admin-settings',
        redirect: (context, state) {
          final authNotifier =
              Provider.of<AuthNotifier>(context, listen: false);
          if (authNotifier.user?.role != UserRole.admin) {
            return AppConstants.routeDashboard;
          }
          return null;
        },
        builder: (context, state) => const AdminSettingsScreen(),
      ),

      GoRoute(
        path: AppConstants.routeSocialization,
        name: 'socialization',
        builder: (context, state) => const SocializationListScreen(),
      ),

      GoRoute(
        path: AppConstants.routeCreateSocialization,
        name: 'create-socialization',
        redirect: (context, state) {
          final role =
              Provider.of<AuthNotifier>(context, listen: false).user?.role;
          if (role != UserRole.tppk && role != UserRole.admin) {
            return AppConstants.routeSocialization;
          }
          return null;
        },
        builder: (context, state) => const CreateSocializationScreen(),
      ),

      GoRoute(
        path: AppConstants.routeEditSocialization,
        name: 'edit-socialization',
        redirect: (context, state) {
          final role =
              Provider.of<AuthNotifier>(context, listen: false).user?.role;
          if (role != UserRole.tppk && role != UserRole.admin) {
            return AppConstants.routeSocialization;
          }
          return null;
        },
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Artikel tidak valid')),
            );
          }
          return EditSocializationScreen(articleId: id);
        },
      ),

      GoRoute(
        path: AppConstants.routeSocializationDetail,
        name: 'socialization-detail',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Artikel tidak valid')),
            );
          }
          return SocializationDetailScreen(articleId: id);
        },
      ),

      GoRoute(
        path: AppConstants.routeCeritaKelas,
        name: 'cerita-kelas',
        builder: (context, state) => const CeritaKelasListScreen(),
      ),

      GoRoute(
        path: AppConstants.routeCreateCeritaKelas,
        name: 'create-cerita-kelas',
        redirect: (context, state) {
          final role =
              Provider.of<AuthNotifier>(context, listen: false).user?.role;
          if (role != UserRole.siswa && role != UserRole.guru) {
            return AppConstants.routeCeritaKelas;
          }
          return null;
        },
        builder: (context, state) => const CreateCeritaKelasScreen(),
      ),

      GoRoute(
        path: AppConstants.routeEditCeritaKelas,
        name: 'edit-cerita-kelas',
        redirect: (context, state) {
          final role =
              Provider.of<AuthNotifier>(context, listen: false).user?.role;
          if (role != UserRole.siswa &&
              role != UserRole.guru &&
              role != UserRole.tppk &&
              role != UserRole.admin) {
            return AppConstants.routeCeritaKelas;
          }
          return null;
        },
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Cerita tidak valid')),
            );
          }
          return EditCeritaKelasScreen(ceritaId: id);
        },
      ),

      GoRoute(
        path: AppConstants.routeCeritaKelasDetail,
        name: 'cerita-kelas-detail',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Cerita tidak valid')),
            );
          }
          return CeritaKelasDetailScreen(ceritaId: id);
        },
      ),
    ],

    // Error handling
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '404 - Page Not Found',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                state.error?.toString() ?? 'Unknown error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppConstants.routeDashboard),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
