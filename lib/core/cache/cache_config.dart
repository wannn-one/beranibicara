import 'package:beranibicara/core/constants/app_constants.dart';

/// Cache configuration for the application
class CacheConfig {
  CacheConfig._(); // Private constructor

  // ============================================================================
  // Cache Box Names
  // ============================================================================

  static const String userBox = 'user_box';
  static const String profileBox = 'profile_box';
  static const String kelasBox = 'kelas_box';
  static const String socializationBox = 'socialization_box';
  static const String metaBox = 'meta_box'; // For cache metadata

  // ============================================================================
  // Cache Durations (TTL - Time To Live)
  // ============================================================================

  /// User cache duration - 1 hour
  /// Refreshed when user data changes
  static const Duration userCacheDuration = AppConstants.cacheUserDuration;

  /// Profile cache duration - 1 hour
  /// Contains role, kelas_id, status info
  static const Duration profileCacheDuration = AppConstants.cacheProfileDuration;

  /// Kelas cache duration - 24 hours
  /// Rarely changes, long cache period
  static const Duration kelasCacheDuration = AppConstants.cacheKelasDuration;

  /// Socialization cache duration - 30 minutes
  /// Content updates frequently
  static const Duration socializationCacheDuration =
      AppConstants.cacheSocializationDuration;

  /// Dashboard stats cache duration - 10 minutes
  /// Real-time stats need frequent refresh
  static const Duration dashboardStatsCacheDuration =
      AppConstants.cacheDashboardStatsDuration;

  // ============================================================================
  // Cache Keys
  // ============================================================================

  /// Current user key
  static const String currentUserKey = 'current_user';

  /// Profile key pattern: 'profile_{userId}'
  static String profileKey(String userId) => 'profile_$userId';

  /// All kelas key
  static const String allKelasKey = 'all_kelas';

  /// Kelas by ID key pattern: 'kelas_{kelasId}'
  static String kelasKey(int kelasId) => 'kelas_$kelasId';

  /// Socialization list key
  static const String socializationListKey = 'socialization_list';

  /// Dashboard stats key pattern: 'dashboard_stats_{userId}'
  static String dashboardStatsKey(String userId) => 'dashboard_stats_$userId';

  // ============================================================================
  // Cacheable vs Non-Cacheable Entities
  // ============================================================================

  /// Entities that should be cached
  static const List<String> cacheableEntities = [
    'kelas', // Rarely changes
    'profiles', // Role lookups for RLS
    'socialization', // Read-heavy content
    'nisn_registry', // Static registry data
  ];

  /// Entities that should NOT be cached (real-time needed)
  static const List<String> noCacheEntities = [
    'reports', // Need real-time updates
    'balasan_laporan', // Instant feedback required
    'notification_history', // Must be real-time
    'log_penanganan', // Audit trail
    'tanggapan_cerita', // Real-time comments
    'device_tokens', // Session-based
  ];

  // ============================================================================
  // Cache Invalidation Events
  // ============================================================================

  /// Events that should trigger cache invalidation
  static const Map<String, List<String>> invalidationEvents = {
    'user_logout': [userBox, profileBox, socializationBox], // Clear user data
    'profile_updated': [profileBox], // Clear profile cache
    'role_changed': [
      profileBox,
      socializationBox
    ], // Clear all (permissions changed)
    'kelas_updated': [kelasBox], // Clear kelas cache
    'socialization_published': [socializationBox], // Clear socialization
  };

  // ============================================================================
  // Cache Size Limits
  // ============================================================================

  /// Maximum number of items per box (to prevent bloat)
  static const int maxItemsPerBox = 1000;

  /// Maximum cache size in MB (approximate)
  static const int maxCacheSizeMB = 50;
}
