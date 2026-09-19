/// App-wide configuration constants
class AppConstants {
  AppConstants._(); // Private constructor

  // App Configuration
  static const String appVersion = '2.0.0';
  static const String appBuildNumber = '7';

  // Legal (Play Store) — override via .env
  static const String urlTermsOfUse =
      'https://beranibicara.site/terms-of-service';
  static const String urlPrivacyPolicy =
      'https://beranibicara.site/privacy-policy';

  // API Configuration (loaded from .env)
  static const String envSupabaseUrl = 'SUPABASE_URL';
  static const String envSupabaseAnonKey = 'SUPABASE_ANON_KEY';
  static const String envGoogleClientId = 'GOOGLE_CLIENT_ID';

  // Storage Buckets
  static const String bucketReportEvidence = 'bukti_laporan';
  static const String bucketSocialization = 'socialization';
  static const String bucketCeritaKelas = 'cerita_kelas';
  static const String bucketProfilePictures = 'profile_pictures';

  // File Upload Constraints
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB in bytes
  static const int maxFilesPerReport = 3;
  static const List<String> allowedFileTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'video/mp4',
    'video/quicktime',
    'application/pdf',
  ];
  static const List<String> allowedFileExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'mp4',
    'mov',
    'pdf',
  ];

  // Text Field Constraints
  static const int minPasswordLength = 6;
  static const int nisnLength = 10;
  static const int minReportDescriptionLength = 10;
  static const int minReportTitleLength = 5;
  static const int maxReportTitleLength = 200;
  static const int maxReportDescriptionLength = 5000;
  static const int maxCeritaKelasJudulLength = 200;
  static const int minCeritaKelasKontenLength = 10;
  static const int maxTanggapanLength = 1000;

  // Cache Keys
  static const String cacheKeyUser = 'user_cache';
  static const String cacheKeyProfile = 'profile_cache';
  static const String cacheKeyKelas = 'kelas_cache';
  static const String cacheKeySocialization = 'socialization_cache';

  // Cache Durations
  static const Duration cacheUserDuration = Duration(hours: 1);
  static const Duration cacheProfileDuration = Duration(hours: 1);
  static const Duration cacheKelasDuration = Duration(hours: 24);
  static const Duration cacheSocializationDuration = Duration(minutes: 30);
  static const Duration cacheDashboardStatsDuration = Duration(minutes: 10);

  // Pagination
  static const int defaultPageSize = 20;
  static const int reportsPageSize = 10;
  static const int socializationPageSize = 10;
  static const int ceritaKelasPageSize = 15;

  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy, HH:mm';
  static const String timeFormat = 'HH:mm';

  // Routing
  static const String routeSplash = '/';
  static const String routeWelcome = '/welcome';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeUpdatePassword = '/update-password';
  static const String authCallbackUrl = 'com.beranibicara.app://callback';
  static const String routeCompleteProfile = '/complete-profile';
  static const String routeDashboard = '/dashboard';
  static const String routeProfile = '/profile';
  static const String routeNotifications = '/notifications';
  static const String routeReports = '/reports';
  static const String routeReportDetail = '/reports/:id';
  static const String routeCreateReport = '/reports/create';
  static const String routeEditReport = '/reports/:id/edit';
  static const String routeSocialization = '/socialization';
  static const String routeSocializationDetail = '/socialization/:id';
  static const String routeCeritaKelas = '/cerita-kelas';
  static const String routeCreateCeritaKelas = '/cerita-kelas/create';
  static const String routeEditCeritaKelas = '/cerita-kelas/:id/edit';
  static const String routeCeritaKelasDetail = '/cerita-kelas/:id';
  static const String routeAdminUsers = '/admin/users';
  static const String routeAdminKelas = '/admin/kelas';
  static const String routeAdminStats = '/admin/stats';
  static const String routeAdminSettings = '/admin/settings';
  static const String routeCreateSocialization = '/socialization/create';
  static const String routeEditSocialization = '/socialization/:id/edit';

  // Database Tables
  static const String tableProfiles = 'profiles';
  static const String tableKelas = 'kelas';
  static const String tableReports = 'reports';
  static const String tableEvidence = 'evidence';
  static const String tableLogPenanganan = 'log_penanganan';
  static const String tableBalasanLaporan = 'balasan_laporan';
  static const String tableSocialization = 'socialization';
  static const String tableCeritaKelas = 'cerita_kelas';
  static const String tableTanggapanCerita = 'tanggapan_cerita';
  static const String tableNisnRegistry = 'nisn_registry';
  static const String tableDeviceTokens = 'device_tokens';
  static const String tableNotificationHistory = 'notification_history';

  // User Roles (matching database enum)
  static const String roleSiswa = 'siswa';
  static const String roleGuru = 'guru';
  static const String roleTPPK = 'tppk';
  static const String roleAdmin = 'admin';

  // User Status (matching database enum)
  static const String userStatusAktif = 'aktif';
  static const String userStatusNonAktif = 'non_aktif';
  static const String userStatusBlocked = 'blocked';

  // Report Status (matching database enum)
  static const String reportStatusBaru = 'baru';
  static const String reportStatusSpam = 'spam';
  static const String reportStatusDitolak = 'ditolak';
  static const String reportStatusDiproses = 'diproses';
  static const String reportStatusSelesai = 'selesai';

  // Tahapan (matching database enum)
  static const String tahapanVerifikasi = 'verifikasi';
  static const String tahapanKonseling = 'konseling';
  static const String tahapanTindakLanjut = 'tindak_lanjut';
  static const String tahapanSelesai = 'selesai';

  // File Types (matching database enum)
  static const String fileTypeImage = 'image';
  static const String fileTypeVideo = 'video';
  static const String fileTypeDocument = 'document';
  static const String fileTypeAudio = 'audio';

  // Animation Durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Snackbar Duration
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration errorSnackbarDuration = Duration(seconds: 5);
}
