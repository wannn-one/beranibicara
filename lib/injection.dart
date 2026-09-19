import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/core/cache/cache_manager.dart';
import 'package:beranibicara/core/cache/cache_config.dart';

// Data Sources
import 'package:beranibicara/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:beranibicara/features/reports/data/datasources/report_remote_datasource.dart';
import 'package:beranibicara/features/balasan/data/datasources/balasan_remote_datasource.dart';
import 'package:beranibicara/features/log_penanganan/data/datasources/log_penanganan_remote_datasource.dart';
import 'package:beranibicara/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:beranibicara/features/socialization/data/datasources/socialization_remote_datasource.dart';
import 'package:beranibicara/features/cerita_kelas/data/datasources/cerita_kelas_remote_datasource.dart';

// Repositories
import 'package:beranibicara/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:beranibicara/features/auth/domain/repositories/auth_repository.dart';
import 'package:beranibicara/features/reports/data/repositories/report_repository_impl.dart';
import 'package:beranibicara/features/reports/domain/repositories/report_repository.dart';
import 'package:beranibicara/features/balasan/data/repositories/balasan_repository_impl.dart';
import 'package:beranibicara/features/balasan/domain/repositories/balasan_repository.dart';
import 'package:beranibicara/features/log_penanganan/data/repositories/log_penanganan_repository_impl.dart';
import 'package:beranibicara/features/log_penanganan/domain/repositories/log_penanganan_repository.dart';
import 'package:beranibicara/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:beranibicara/features/admin/domain/repositories/admin_repository.dart';
import 'package:beranibicara/features/socialization/data/repositories/socialization_repository_impl.dart';
import 'package:beranibicara/features/socialization/domain/repositories/socialization_repository.dart';
import 'package:beranibicara/features/cerita_kelas/data/repositories/cerita_kelas_repository_impl.dart';
import 'package:beranibicara/features/cerita_kelas/domain/repositories/cerita_kelas_repository.dart';

// Use Cases
import 'package:beranibicara/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/verify_nisn_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/update_password_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/watch_auth_session_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/is_password_recovery_launch_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/get_kelas_list_usecase.dart';
import 'package:beranibicara/features/auth/domain/usecases/complete_student_profile_usecase.dart';
import 'package:beranibicara/features/reports/domain/usecases/create_report_usecase.dart';
import 'package:beranibicara/features/reports/domain/usecases/get_report_by_id_usecase.dart';
import 'package:beranibicara/features/reports/domain/usecases/get_reports_by_reporter_usecase.dart';
import 'package:beranibicara/features/reports/domain/usecases/get_all_reports_usecase.dart';
import 'package:beranibicara/features/reports/domain/usecases/update_report_status_usecase.dart';
import 'package:beranibicara/features/reports/domain/usecases/update_report_usecase.dart';
import 'package:beranibicara/features/reports/domain/usecases/delete_report_usecase.dart';
import 'package:beranibicara/features/reports/domain/usecases/upload_evidence_usecase.dart';
import 'package:beranibicara/features/reports/domain/usecases/get_evidence_by_report_id_usecase.dart';
import 'package:beranibicara/features/reports/domain/usecases/delete_evidence_usecase.dart';
import 'package:beranibicara/features/balasan/domain/usecases/create_balasan_usecase.dart';
import 'package:beranibicara/features/balasan/domain/usecases/get_balasan_by_report_id_usecase.dart';
import 'package:beranibicara/features/balasan/domain/usecases/delete_balasan_usecase.dart';
import 'package:beranibicara/features/balasan/domain/usecases/watch_balasan_by_report_id_usecase.dart';
import 'package:beranibicara/features/log_penanganan/domain/usecases/get_log_penanganan_usecase.dart';
import 'package:beranibicara/features/log_penanganan/domain/usecases/create_log_penanganan_usecase.dart';
import 'package:beranibicara/features/admin/domain/usecases/list_profiles_usecase.dart';
import 'package:beranibicara/features/admin/domain/usecases/update_user_role_usecase.dart';
import 'package:beranibicara/features/admin/domain/usecases/update_user_status_usecase.dart';
import 'package:beranibicara/features/admin/domain/usecases/list_kelas_usecase.dart';
import 'package:beranibicara/features/admin/domain/usecases/create_kelas_usecase.dart';
import 'package:beranibicara/features/admin/domain/usecases/assign_wali_kelas_usecase.dart';
import 'package:beranibicara/features/admin/domain/usecases/update_student_kelas_usecase.dart';
import 'package:beranibicara/features/admin/domain/usecases/get_admin_stats_usecase.dart';
import 'package:beranibicara/features/socialization/domain/usecases/list_socialization_usecase.dart';
import 'package:beranibicara/features/socialization/domain/usecases/get_socialization_by_id_usecase.dart';
import 'package:beranibicara/features/socialization/domain/usecases/create_socialization_usecase.dart';
import 'package:beranibicara/features/socialization/domain/usecases/update_socialization_usecase.dart';
import 'package:beranibicara/features/socialization/domain/usecases/delete_socialization_usecase.dart';
import 'package:beranibicara/features/cerita_kelas/domain/usecases/list_cerita_kelas_usecase.dart';
import 'package:beranibicara/features/cerita_kelas/domain/usecases/get_cerita_kelas_by_id_usecase.dart';
import 'package:beranibicara/features/cerita_kelas/domain/usecases/create_cerita_kelas_usecase.dart';
import 'package:beranibicara/features/cerita_kelas/domain/usecases/update_cerita_kelas_usecase.dart';
import 'package:beranibicara/features/cerita_kelas/domain/usecases/delete_cerita_kelas_usecase.dart';
import 'package:beranibicara/features/cerita_kelas/domain/usecases/list_tanggapan_cerita_usecase.dart';
import 'package:beranibicara/features/cerita_kelas/domain/usecases/add_tanggapan_cerita_usecase.dart';
import 'package:beranibicara/features/cerita_kelas/domain/usecases/delete_tanggapan_cerita_usecase.dart';
import 'package:beranibicara/features/cerita_kelas/domain/usecases/list_wali_kelas_options_usecase.dart';
import 'package:beranibicara/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:beranibicara/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:beranibicara/features/notifications/domain/repositories/notification_repository.dart';
import 'package:beranibicara/features/notifications/domain/usecases/get_unread_notification_count_usecase.dart';
import 'package:beranibicara/features/notifications/domain/usecases/list_notifications_usecase.dart';
import 'package:beranibicara/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:beranibicara/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:beranibicara/features/notifications/domain/usecases/register_device_token_usecase.dart';
import 'package:beranibicara/features/notifications/domain/usecases/unregister_device_token_usecase.dart';

// Providers
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/reports/presentation/providers/report_notifier.dart';
import 'package:beranibicara/features/balasan/presentation/providers/balasan_notifier.dart';
import 'package:beranibicara/features/log_penanganan/presentation/providers/log_penanganan_notifier.dart';
import 'package:beranibicara/features/admin/presentation/providers/admin_notifier.dart';
import 'package:beranibicara/features/socialization/presentation/providers/socialization_notifier.dart';
import 'package:beranibicara/features/cerita_kelas/presentation/providers/cerita_kelas_notifier.dart';
import 'package:beranibicara/features/notifications/presentation/providers/notification_notifier.dart';

/// Dependency Injection Container
/// Contains all singleton instances for the app
class Injection {
  Injection._(); // Private constructor

  // Core Dependencies
  /// Supabase client (from Supabase.instance)
  static SupabaseClient get supabaseClient => Supabase.instance.client;

  // Cache Managers
  static final CacheManager userCacheManager = CacheManager(CacheConfig.userBox);
  static final CacheManager profileCacheManager = CacheManager(CacheConfig.profileBox);
  static final CacheManager kelasCacheManager = CacheManager(CacheConfig.kelasBox);
  static final CacheManager socializationCacheManager =
      CacheManager(CacheConfig.socializationBox);

  // ============================================================================
  // Auth Feature
  // ============================================================================

  // Data Sources
  static final AuthRemoteDataSource authRemoteDataSource =
      AuthRemoteDataSource(supabaseClient);

  // Repositories
  static final AuthRepository authRepository =
      AuthRepositoryImpl(authRemoteDataSource);

  // Use Cases
  static final SignInUseCase signInUseCase = SignInUseCase(authRepository);
  static final SignInWithGoogleUseCase signInWithGoogleUseCase =
      SignInWithGoogleUseCase(authRepository);
  static final SignUpUseCase signUpUseCase = SignUpUseCase(authRepository);
  static final SignOutUseCase signOutUseCase = SignOutUseCase(authRepository);
  static final GetCurrentUserUseCase getCurrentUserUseCase =
      GetCurrentUserUseCase(authRepository);
  static final VerifyNisnUseCase verifyNisnUseCase =
      VerifyNisnUseCase(authRepository);
  static final ResetPasswordUseCase resetPasswordUseCase =
      ResetPasswordUseCase(authRepository);
  static final UpdatePasswordUseCase updatePasswordUseCase =
      UpdatePasswordUseCase(authRepository);
  static final WatchAuthSessionUseCase watchAuthSessionUseCase =
      WatchAuthSessionUseCase(authRepository);
  static final IsPasswordRecoveryLaunchUseCase isPasswordRecoveryLaunchUseCase =
      IsPasswordRecoveryLaunchUseCase(authRepository);
  static final UpdateProfileUseCase updateProfileUseCase =
      UpdateProfileUseCase(authRepository);
  static final GetKelasListUseCase getKelasListUseCase =
      GetKelasListUseCase(authRepository);
  static final CompleteStudentProfileUseCase completeStudentProfileUseCase =
      CompleteStudentProfileUseCase(authRepository);

  // ============================================================================
  // Reports Feature
  // ============================================================================

  // Data Sources
  static final ReportRemoteDataSource reportRemoteDataSource =
      ReportRemoteDataSource(supabaseClient);

  // Repositories
  static final ReportRepository reportRepository =
      ReportRepositoryImpl(reportRemoteDataSource);

  // Use Cases
  static final CreateReportUseCase createReportUseCase =
      CreateReportUseCase(reportRepository);
  static final GetReportByIdUseCase getReportByIdUseCase =
      GetReportByIdUseCase(reportRepository);
  static final GetReportsByReporterUseCase getReportsByReporterUseCase =
      GetReportsByReporterUseCase(reportRepository);
  static final GetAllReportsUseCase getAllReportsUseCase =
      GetAllReportsUseCase(reportRepository);
  static final UpdateReportStatusUseCase updateReportStatusUseCase =
      UpdateReportStatusUseCase(reportRepository);
  static final UpdateReportUseCase updateReportUseCase =
      UpdateReportUseCase(reportRepository);
  static final DeleteReportUseCase deleteReportUseCase =
      DeleteReportUseCase(reportRepository);
  static final UploadEvidenceUseCase uploadEvidenceUseCase =
      UploadEvidenceUseCase(reportRepository);
  static final GetEvidenceByReportIdUseCase getEvidenceByReportIdUseCase =
      GetEvidenceByReportIdUseCase(reportRepository);
  static final DeleteEvidenceUseCase deleteEvidenceUseCase =
      DeleteEvidenceUseCase(reportRepository);

  // ============================================================================
  // Balasan (Report Replies) Feature
  // ============================================================================

  // Data Sources
  static final BalasanRemoteDataSource balasanRemoteDataSource =
      BalasanRemoteDataSource(supabaseClient);

  // Repositories
  static final BalasanRepository balasanRepository =
      BalasanRepositoryImpl(remoteDataSource: balasanRemoteDataSource);

  // Use Cases
  static final CreateBalasanUseCase createBalasanUseCase =
      CreateBalasanUseCase(balasanRepository);
  static final GetBalasanByReportIdUseCase getBalasanByReportIdUseCase =
      GetBalasanByReportIdUseCase(balasanRepository);
  static final DeleteBalasanUseCase deleteBalasanUseCase =
      DeleteBalasanUseCase(balasanRepository);
  static final WatchBalasanByReportIdUseCase watchBalasanByReportIdUseCase =
      WatchBalasanByReportIdUseCase(balasanRepository);

  // ============================================================================
  // Log Penanganan Feature
  // ============================================================================

  static final LogPenangananRemoteDataSource logPenangananRemoteDataSource =
      LogPenangananRemoteDataSource(supabaseClient);
  static final LogPenangananRepository logPenangananRepository =
      LogPenangananRepositoryImpl(logPenangananRemoteDataSource);
  static final GetLogPenangananUseCase getLogPenangananUseCase =
      GetLogPenangananUseCase(logPenangananRepository);
  static final CreateLogPenangananUseCase createLogPenangananUseCase =
      CreateLogPenangananUseCase(logPenangananRepository);

  // ============================================================================
  // Admin Feature
  // ============================================================================

  static final AdminRemoteDataSource adminRemoteDataSource =
      AdminRemoteDataSource(supabaseClient);
  static final AdminRepository adminRepository =
      AdminRepositoryImpl(adminRemoteDataSource);
  static final ListProfilesUseCase listProfilesUseCase =
      ListProfilesUseCase(adminRepository);
  static final UpdateUserRoleUseCase updateUserRoleUseCase =
      UpdateUserRoleUseCase(adminRepository);
  static final UpdateUserStatusUseCase updateUserStatusUseCase =
      UpdateUserStatusUseCase(adminRepository);
  static final ListKelasUseCase listKelasUseCase =
      ListKelasUseCase(adminRepository);
  static final CreateKelasUseCase createKelasUseCase =
      CreateKelasUseCase(adminRepository);
  static final AssignWaliKelasUseCase assignWaliKelasUseCase =
      AssignWaliKelasUseCase(adminRepository);
  static final UpdateStudentKelasUseCase updateStudentKelasUseCase =
      UpdateStudentKelasUseCase(adminRepository);
  static final GetAdminStatsUseCase getAdminStatsUseCase =
      GetAdminStatsUseCase(adminRepository);

  // ============================================================================
  // Socialization Feature
  // ============================================================================

  static final SocializationRemoteDataSource socializationRemoteDataSource =
      SocializationRemoteDataSource(supabaseClient);
  static final SocializationRepository socializationRepository =
      SocializationRepositoryImpl(socializationRemoteDataSource);
  static final ListSocializationUseCase listSocializationUseCase =
      ListSocializationUseCase(socializationRepository);
  static final GetSocializationByIdUseCase getSocializationByIdUseCase =
      GetSocializationByIdUseCase(socializationRepository);
  static final CreateSocializationUseCase createSocializationUseCase =
      CreateSocializationUseCase(socializationRepository);
  static final UpdateSocializationUseCase updateSocializationUseCase =
      UpdateSocializationUseCase(socializationRepository);
  static final DeleteSocializationUseCase deleteSocializationUseCase =
      DeleteSocializationUseCase(socializationRepository);

  static final CeritaKelasRemoteDataSource ceritaKelasRemoteDataSource =
      CeritaKelasRemoteDataSource(supabaseClient);
  static final CeritaKelasRepository ceritaKelasRepository =
      CeritaKelasRepositoryImpl(ceritaKelasRemoteDataSource);
  static final ListCeritaKelasUseCase listCeritaKelasUseCase =
      ListCeritaKelasUseCase(ceritaKelasRepository);
  static final GetCeritaKelasByIdUseCase getCeritaKelasByIdUseCase =
      GetCeritaKelasByIdUseCase(ceritaKelasRepository);
  static final CreateCeritaKelasUseCase createCeritaKelasUseCase =
      CreateCeritaKelasUseCase(ceritaKelasRepository);
  static final UpdateCeritaKelasUseCase updateCeritaKelasUseCase =
      UpdateCeritaKelasUseCase(ceritaKelasRepository);
  static final DeleteCeritaKelasUseCase deleteCeritaKelasUseCase =
      DeleteCeritaKelasUseCase(ceritaKelasRepository);
  static final ListTanggapanCeritaUseCase listTanggapanCeritaUseCase =
      ListTanggapanCeritaUseCase(ceritaKelasRepository);
  static final AddTanggapanCeritaUseCase addTanggapanCeritaUseCase =
      AddTanggapanCeritaUseCase(ceritaKelasRepository);
  static final DeleteTanggapanCeritaUseCase deleteTanggapanCeritaUseCase =
      DeleteTanggapanCeritaUseCase(ceritaKelasRepository);
  static final ListWaliKelasOptionsUseCase listWaliKelasOptionsUseCase =
      ListWaliKelasOptionsUseCase(ceritaKelasRepository);

  static final NotificationRemoteDataSource notificationRemoteDataSource =
      NotificationRemoteDataSource(supabaseClient);
  static final NotificationRepository notificationRepository =
      NotificationRepositoryImpl(notificationRemoteDataSource);
  static final RegisterDeviceTokenUseCase registerDeviceTokenUseCase =
      RegisterDeviceTokenUseCase(notificationRepository);
  static final UnregisterDeviceTokenUseCase unregisterDeviceTokenUseCase =
      UnregisterDeviceTokenUseCase(notificationRepository);
  static final ListNotificationsUseCase listNotificationsUseCase =
      ListNotificationsUseCase(notificationRepository);
  static final GetUnreadNotificationCountUseCase
      getUnreadNotificationCountUseCase =
      GetUnreadNotificationCountUseCase(notificationRepository);
  static final MarkNotificationReadUseCase markNotificationReadUseCase =
      MarkNotificationReadUseCase(notificationRepository);
  static final MarkAllNotificationsReadUseCase
      markAllNotificationsReadUseCase =
      MarkAllNotificationsReadUseCase(notificationRepository);

  // Providers Setup
  /// Get list of providers for MultiProvider
  static List<SingleChildWidget> get providers {
    return [
      // Auth Provider
      ChangeNotifierProvider<AuthNotifier>(
        create: (_) => AuthNotifier(
          signInUseCase: signInUseCase,
          signInWithGoogleUseCase: signInWithGoogleUseCase,
          signUpUseCase: signUpUseCase,
          signOutUseCase: signOutUseCase,
          getCurrentUserUseCase: getCurrentUserUseCase,
          verifyNisnUseCase: verifyNisnUseCase,
          resetPasswordUseCase: resetPasswordUseCase,
          updatePasswordUseCase: updatePasswordUseCase,
          updateProfileUseCase: updateProfileUseCase,
          getKelasListUseCase: getKelasListUseCase,
          completeStudentProfileUseCase: completeStudentProfileUseCase,
          watchAuthSessionUseCase: watchAuthSessionUseCase,
          isPasswordRecoveryLaunchUseCase: isPasswordRecoveryLaunchUseCase,
          unregisterDeviceTokenUseCase: unregisterDeviceTokenUseCase,
        )..initialize(),
      ),

      // Reports Provider
      ChangeNotifierProvider<ReportNotifier>(
        create: (_) => ReportNotifier(
          createReportUseCase: createReportUseCase,
          getReportByIdUseCase: getReportByIdUseCase,
          getReportsByReporterUseCase: getReportsByReporterUseCase,
          getAllReportsUseCase: getAllReportsUseCase,
          updateReportStatusUseCase: updateReportStatusUseCase,
          updateReportUseCase: updateReportUseCase,
          deleteReportUseCase: deleteReportUseCase,
          uploadEvidenceUseCase: uploadEvidenceUseCase,
          getEvidenceByReportIdUseCase: getEvidenceByReportIdUseCase,
          deleteEvidenceUseCase: deleteEvidenceUseCase,
        ),
      ),

      // Balasan Provider
      ChangeNotifierProvider<BalasanNotifier>(
        create: (_) => BalasanNotifier(
          createBalasanUseCase: createBalasanUseCase,
          getBalasanByReportIdUseCase: getBalasanByReportIdUseCase,
          deleteBalasanUseCase: deleteBalasanUseCase,
          watchBalasanByReportIdUseCase: watchBalasanByReportIdUseCase,
        ),
      ),

      ChangeNotifierProvider<LogPenangananNotifier>(
        create: (_) => LogPenangananNotifier(
          getLogPenangananUseCase: getLogPenangananUseCase,
          createLogPenangananUseCase: createLogPenangananUseCase,
        ),
      ),

      ChangeNotifierProvider<AdminNotifier>(
        create: (_) => AdminNotifier(
          listProfilesUseCase: listProfilesUseCase,
          updateUserRoleUseCase: updateUserRoleUseCase,
          updateUserStatusUseCase: updateUserStatusUseCase,
          listKelasUseCase: listKelasUseCase,
          createKelasUseCase: createKelasUseCase,
          assignWaliKelasUseCase: assignWaliKelasUseCase,
          updateStudentKelasUseCase: updateStudentKelasUseCase,
          getAdminStatsUseCase: getAdminStatsUseCase,
        ),
      ),

      ChangeNotifierProvider<SocializationNotifier>(
        create: (_) => SocializationNotifier(
          listSocializationUseCase: listSocializationUseCase,
          getSocializationByIdUseCase: getSocializationByIdUseCase,
          createSocializationUseCase: createSocializationUseCase,
          updateSocializationUseCase: updateSocializationUseCase,
          deleteSocializationUseCase: deleteSocializationUseCase,
        ),
      ),

      ChangeNotifierProvider<CeritaKelasNotifier>(
        create: (_) => CeritaKelasNotifier(
          listCeritaKelasUseCase: listCeritaKelasUseCase,
          getCeritaKelasByIdUseCase: getCeritaKelasByIdUseCase,
          createCeritaKelasUseCase: createCeritaKelasUseCase,
          updateCeritaKelasUseCase: updateCeritaKelasUseCase,
          deleteCeritaKelasUseCase: deleteCeritaKelasUseCase,
          listTanggapanCeritaUseCase: listTanggapanCeritaUseCase,
          addTanggapanCeritaUseCase: addTanggapanCeritaUseCase,
          deleteTanggapanCeritaUseCase: deleteTanggapanCeritaUseCase,
          listWaliKelasOptionsUseCase: listWaliKelasOptionsUseCase,
        ),
      ),

      ChangeNotifierProvider<NotificationNotifier>(
        create: (_) => NotificationNotifier(
          listNotificationsUseCase: listNotificationsUseCase,
          getUnreadNotificationCountUseCase: getUnreadNotificationCountUseCase,
          markNotificationReadUseCase: markNotificationReadUseCase,
          markAllNotificationsReadUseCase: markAllNotificationsReadUseCase,
          registerDeviceTokenUseCase: registerDeviceTokenUseCase,
        ),
      ),
    ];
  }
}
