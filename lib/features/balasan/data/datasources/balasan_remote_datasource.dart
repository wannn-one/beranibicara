import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/core/errors/exceptions.dart';
import 'package:beranibicara/features/balasan/data/models/balasan_laporan_model.dart';

/// Remote data source for Balasan Laporan operations with Supabase
/// 
/// Handles all Supabase interactions for report replies, including:
/// - CRUD operations
/// - Real-time subscriptions
/// - Author info joins
class BalasanRemoteDataSource {
  final SupabaseClient supabaseClient;

  BalasanRemoteDataSource(this.supabaseClient);

  /// Create a new reply to a report
  /// 
  /// Inserts a new row in balasan_laporan table
  /// Returns the created reply with author info
  Future<BalasanLaporanModel> createBalasan({
    required int reportId,
    required String authorId,
    required String pesan,
  }) async {
    try {
      final response = await supabaseClient
          .from('balasan_laporan')
          .insert({
            'report_id': reportId,
            'author_id': authorId,
            'pesan': pesan,
          })
          .select('''
            id,
            report_id,
            author_id,
            pesan,
            created_at,
            profiles!inner(
              full_name,
              role
            )
          ''')
          .single();

      // Map the joined profile data
      final balasanData = {
        'id': response['id'],
        'report_id': response['report_id'],
        'author_id': response['author_id'],
        'pesan': response['pesan'],
        'created_at': response['created_at'],
        'author_name': response['profiles']['full_name'],
        'author_role': response['profiles']['role'],
      };

      return BalasanLaporanModel.fromJson(balasanData);
    } on PostgrestException catch (e) {
      if (e.code == '23503') {
        // Foreign key violation
        throw NotFoundException(message: 'Laporan tidak ditemukan');
      } else if (e.code == '42501') {
        // Permission denied by RLS
        throw PermissionException(message: 'Anda tidak memiliki izin untuk menambahkan balasan');
      }
      throw ServerException(message: 'Gagal membuat balasan: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Gagal membuat balasan: $e');
    }
  }

  /// Get all replies for a specific report
  /// 
  /// Returns replies with author info, ordered by created_at ASC (oldest first)
  Future<List<BalasanLaporanModel>> getBalasanByReportId(int reportId) async {
    try {
      final response = await supabaseClient
          .from('balasan_laporan')
          .select('''
            id,
            report_id,
            author_id,
            pesan,
            created_at,
            profiles!inner(
              full_name,
              role
            )
          ''')
          .eq('report_id', reportId)
          .order('created_at', ascending: true);

      return (response as List).map((json) {
        final balasanData = {
          'id': json['id'],
          'report_id': json['report_id'],
          'author_id': json['author_id'],
          'pesan': json['pesan'],
          'created_at': json['created_at'],
          'author_name': json['profiles']['full_name'],
          'author_role': json['profiles']['role'],
        };
        return BalasanLaporanModel.fromJson(balasanData);
      }).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal mengambil balasan: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Gagal mengambil balasan: $e');
    }
  }

  /// Delete a reply
  /// 
  /// Only TPPK who created it or Admin can delete
  /// RLS will enforce authorization
  Future<void> deleteBalasan({
    required int balasanId,
    required String userId,
  }) async {
    try {
      await supabaseClient
          .from('balasan_laporan')
          .delete()
          .eq('id', balasanId)
          .eq('author_id', userId); // Ensure user owns the reply

      // If no error thrown, deletion was successful
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw PermissionException(message: 'Anda tidak memiliki izin untuk menghapus balasan ini');
      }
      throw ServerException(message: 'Gagal menghapus balasan: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Gagal menghapus balasan: $e');
    }
  }

  /// Watch replies in real-time using Supabase Realtime
  /// 
  /// Returns a stream that emits new list of replies whenever changes occur
  Stream<List<BalasanLaporanModel>> watchBalasanByReportId(int reportId) {
    final controller = StreamController<List<BalasanLaporanModel>>();

    // Initial load
    getBalasanByReportId(reportId).then((balasan) {
      if (!controller.isClosed) {
        controller.add(balasan);
      }
    });

    // Subscribe to real-time changes
    final subscription = supabaseClient
        .channel('balasan_laporan:report_$reportId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'balasan_laporan',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'report_id',
            value: reportId,
          ),
          callback: (payload) async {
            // Reload all balasan when insert occurs
            try {
              final balasan = await getBalasanByReportId(reportId);
              if (!controller.isClosed) {
                controller.add(balasan);
              }
            } catch (e) {
              if (!controller.isClosed) {
                controller.addError(e);
              }
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'balasan_laporan',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'report_id',
            value: reportId,
          ),
          callback: (payload) async {
            // Reload all balasan when delete occurs
            try {
              final balasan = await getBalasanByReportId(reportId);
              if (!controller.isClosed) {
                controller.add(balasan);
              }
            } catch (e) {
              if (!controller.isClosed) {
                controller.addError(e);
              }
            }
          },
        )
        .subscribe();

    // Cleanup on stream close
    controller.onCancel = () {
      subscription.unsubscribe();
      controller.close();
    };

    return controller.stream;
  }
}
