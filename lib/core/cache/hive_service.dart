import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:beranibicara/core/cache/cache_config.dart';

/// Service for initializing and managing Hive
class HiveService {
  HiveService._(); // Private constructor

  static bool _initialized = false;

  /// Initialize Hive and open all required boxes
  static Future<void> init() async {
    if (_initialized) {
      return; // Already initialized
    }

    try {
      // Get application documents directory
      final appDocDir = await getApplicationDocumentsDirectory();

      // Initialize Hive with Flutter
      await Hive.initFlutter(appDocDir.path);

      // Register type adapters here if needed
      // Example: Hive.registerAdapter(UserModelAdapter());
      // Note: For now, we'll use JSON serialization through boxes
      // Type adapters can be generated later with hive_generator

      // Open all required boxes
      await Future.wait([
        Hive.openBox(CacheConfig.userBox),
        Hive.openBox(CacheConfig.profileBox),
        Hive.openBox(CacheConfig.kelasBox),
        Hive.openBox(CacheConfig.socializationBox),
        Hive.openBox(CacheConfig.metaBox),
      ]);

      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Hive: $e');
    }
  }

  /// Check if Hive is initialized
  static bool get isInitialized => _initialized;

  /// Get a box by name
  static Box getBox(String boxName) {
    if (!_initialized) {
      throw Exception('HiveService not initialized. Call init() first.');
    }
    return Hive.box(boxName);
  }

  /// Clear all data from a specific box
  static Future<void> clearBox(String boxName) async {
    if (!_initialized) return;

    final box = Hive.box(boxName);
    await box.clear();
  }

  /// Clear all boxes
  static Future<void> clearAll() async {
    if (!_initialized) return;

    await Future.wait([
      clearBox(CacheConfig.userBox),
      clearBox(CacheConfig.profileBox),
      clearBox(CacheConfig.kelasBox),
      clearBox(CacheConfig.socializationBox),
      clearBox(CacheConfig.metaBox),
    ]);
  }

  /// Delete all Hive data from disk
  static Future<void> deleteFromDisk() async {
    await Hive.deleteFromDisk();
    _initialized = false;
  }

  /// Close all boxes
  static Future<void> closeAll() async {
    if (!_initialized) return;

    await Hive.close();
    _initialized = false;
  }

  /// Get cache statistics
  static Map<String, int> getCacheStats() {
    if (!_initialized) {
      return {};
    }

    return {
      CacheConfig.userBox: Hive.box(CacheConfig.userBox).length,
      CacheConfig.profileBox: Hive.box(CacheConfig.profileBox).length,
      CacheConfig.kelasBox: Hive.box(CacheConfig.kelasBox).length,
      CacheConfig.socializationBox:
          Hive.box(CacheConfig.socializationBox).length,
      CacheConfig.metaBox: Hive.box(CacheConfig.metaBox).length,
    };
  }

  /// Check cache health (size limits, etc.)
  static Future<bool> checkCacheHealth() async {
    if (!_initialized) return false;

    try {
      final stats = getCacheStats();

      // Check if any box exceeds max items
      for (final entry in stats.entries) {
        if (entry.value > CacheConfig.maxItemsPerBox) {
          // Clear oldest entries if exceeded
          await _pruneBox(entry.key);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Prune a box to remove oldest entries
  static Future<void> _pruneBox(String boxName) async {
    final box = Hive.box(boxName);
    final itemsToRemove = box.length - (CacheConfig.maxItemsPerBox ~/ 2);

    if (itemsToRemove > 0) {
      // Remove first N items (oldest)
      for (var i = 0; i < itemsToRemove; i++) {
        await box.deleteAt(0);
      }
    }
  }
}
