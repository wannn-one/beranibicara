import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/core/errors/exceptions.dart';
import 'package:beranibicara/features/notifications/data/models/notification_model.dart';

class NotificationRemoteDataSource {
  final SupabaseClient supabaseClient;

  NotificationRemoteDataSource(this.supabaseClient);

  Future<void> upsertToken({
    required String token,
    String? deviceName,
    String? deviceOs,
  }) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw ServerException(message: 'Not authenticated');
    }

    try {
      await supabaseClient.from(AppConstants.tableDeviceTokens).upsert(
        {
          'user_id': userId,
          'fcm_token': token,
          'device_name': deviceName,
          'device_os': deviceOs,
          'is_active': true,
          'last_used_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'fcm_token',
      );
    } catch (e) {
      throw ServerException(message: 'Gagal menyimpan token perangkat: $e');
    }
  }

  Future<void> deactivateToken(String token) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabaseClient
          .from(AppConstants.tableDeviceTokens)
          .update({
            'is_active': false,
            'last_used_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('fcm_token', token)
          .eq('user_id', userId);
    } catch (e) {
      throw ServerException(message: 'Gagal menonaktifkan token: $e');
    }
  }

  Future<List<NotificationModel>> listNotifications() async {
    try {
      final rows = await supabaseClient
          .from(AppConstants.tableNotificationHistory)
          .select()
          .order('sent_at', ascending: false)
          .limit(50);
      return (rows as List)
          .map((row) => NotificationModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Gagal memuat notifikasi: $e');
    }
  }

  Future<int> unreadCount() async {
    try {
      final rows = await supabaseClient
          .from(AppConstants.tableNotificationHistory)
          .select('id')
          .isFilter('read_at', null);
      return (rows as List).length;
    } catch (e) {
      throw ServerException(message: 'Gagal menghitung notifikasi: $e');
    }
  }

  Future<void> markRead(int id) async {
    try {
      await supabaseClient.rpc(
        'mark_notification_read',
        params: {'notification_id': id},
      );
    } catch (e) {
      throw ServerException(message: 'Gagal menandai notifikasi: $e');
    }
  }

  Future<void> markAllRead() async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw ServerException(message: 'Not authenticated');
    }
    try {
      await supabaseClient.rpc(
        'mark_all_notifications_read',
        params: {'p_user_id': userId},
      );
    } catch (e) {
      throw ServerException(message: 'Gagal menandai semua notifikasi: $e');
    }
  }
}
