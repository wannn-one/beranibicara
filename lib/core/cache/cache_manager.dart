import 'package:hive/hive.dart';
import 'package:beranibicara/core/cache/hive_service.dart';

/// Generic cache manager for handling cached data with TTL
class CacheManager {
  final String boxName;
  late final Box _box;

  CacheManager(this.boxName) {
    _box = HiveService.getBox(boxName);
  }

  /// Put data into cache with optional TTL
  Future<void> put<T>(
    String key,
    T value, {
    Duration? ttl,
  }) async {
    try {
      final entry = CacheEntry<T>(
        data: value,
        timestamp: DateTime.now(),
        ttl: ttl,
      );

      // Store as Map (since we can't use type adapters yet)
      await _box.put(key, entry.toJson());
    } catch (e) {
      throw Exception('Failed to cache data: $e');
    }
  }

  /// Get data from cache
  /// Returns null if key doesn't exist or data is expired
  T? get<T>(String key) {
    try {
      final data = _box.get(key);
      if (data == null) return null;

      // Parse the cached entry
      final entry = CacheEntry<T>.fromJson(data as Map<dynamic, dynamic>);

      // Check if expired
      if (entry.isExpired) {
        _box.delete(key); // Clean up expired data
        return null;
      }

      return entry.data;
    } catch (e) {
      // If parsing fails, delete corrupted data
      _box.delete(key);
      return null;
    }
  }

  /// Check if key exists and is not expired
  bool has(String key) {
    try {
      final data = _box.get(key);
      if (data == null) return false;

      final entry = CacheEntry.fromJson(data as Map<dynamic, dynamic>);

      if (entry.isExpired) {
        _box.delete(key);
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a specific key
  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  /// Clear all data in this cache manager's box
  Future<void> clear() async {
    await _box.clear();
  }

  /// Get all keys in the box
  Iterable<String> get keys => _box.keys.cast<String>();

  /// Get number of items in cache
  int get length => _box.length;

  /// Check if cache is empty
  bool get isEmpty => _box.isEmpty;

  /// Check if cache is not empty
  bool get isNotEmpty => _box.isNotEmpty;

  /// Delete all expired entries
  Future<int> cleanExpired() async {
    int deletedCount = 0;

    for (final key in _box.keys) {
      try {
        final data = _box.get(key);
        if (data != null) {
          final entry = CacheEntry.fromJson(data as Map<dynamic, dynamic>);
          if (entry.isExpired) {
            await _box.delete(key);
            deletedCount++;
          }
        }
      } catch (e) {
        // Delete corrupted entries
        await _box.delete(key);
        deletedCount++;
      }
    }

    return deletedCount;
  }

  /// Refresh TTL for a key (extend expiration time)
  Future<bool> refreshTTL(String key, Duration newTtl) async {
    try {
      final data = _box.get(key);
      if (data == null) return false;

      final entry = CacheEntry.fromJson(data as Map<dynamic, dynamic>);
      
      // Create new entry with updated timestamp and TTL
      final refreshedEntry = CacheEntry(
        data: entry.data,
        timestamp: DateTime.now(),
        ttl: newTtl,
      );

      await _box.put(key, refreshedEntry.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Cache entry wrapper with TTL support
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration? ttl;

  CacheEntry({
    required this.data,
    required this.timestamp,
    this.ttl,
  });

  /// Check if cache entry is expired
  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(timestamp) > ttl!;
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl?.inMilliseconds,
    };
  }

  /// Create from JSON
  factory CacheEntry.fromJson(Map<dynamic, dynamic> json) {
    return CacheEntry<T>(
      data: json['data'] as T,
      timestamp: DateTime.parse(json['timestamp'] as String),
      ttl: json['ttl'] != null
          ? Duration(milliseconds: json['ttl'] as int)
          : null,
    );
  }
}
