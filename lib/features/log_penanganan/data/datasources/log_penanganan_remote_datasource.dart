import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/core/errors/exceptions.dart';
import 'package:beranibicara/features/log_penanganan/data/models/log_penanganan_model.dart';

class LogPenangananRemoteDataSource {
  final SupabaseClient supabaseClient;

  LogPenangananRemoteDataSource(this.supabaseClient);

  Map<String, dynamic> _mapRow(Map<String, dynamic> json) {
    final profile = json['profiles'];
    return {
      'id': json['id'],
      'report_id': json['report_id'],
      'author_id': json['author_id'],
      'catatan': json['catatan'],
      'tahapan': json['tahapan'],
      'created_at': json['created_at'],
      'author_name': profile is Map ? profile['full_name'] : null,
    };
  }

  Future<List<LogPenangananModel>> getByReportId(int reportId) async {
    try {
      final response = await supabaseClient
          .from('log_penanganan')
          .select('''
            id,
            report_id,
            author_id,
            catatan,
            tahapan,
            created_at,
            profiles!inner(full_name)
          ''')
          .eq('report_id', reportId)
          .order('created_at', ascending: true);

      return (response as List)
          .map(
            (json) => LogPenangananModel.fromJson(
              _mapRow(json as Map<String, dynamic>),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal memuat log penanganan: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Gagal memuat log penanganan: $e');
    }
  }

  Future<LogPenangananModel> create({
    required int reportId,
    required String authorId,
    required String catatan,
    required String tahapan,
  }) async {
    try {
      final response = await supabaseClient
          .from('log_penanganan')
          .insert({
            'report_id': reportId,
            'author_id': authorId,
            'catatan': catatan,
            'tahapan': tahapan,
          })
          .select('''
            id,
            report_id,
            author_id,
            catatan,
            tahapan,
            created_at,
            profiles!inner(full_name)
          ''')
          .single();

      return LogPenangananModel.fromJson(_mapRow(response));
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw PermissionException(
          message: 'Anda tidak memiliki izin menambah log penanganan',
        );
      }
      throw ServerException(message: 'Gagal menambah log: ${e.message}');
    } catch (e) {
      if (e is PermissionException) rethrow;
      throw ServerException(message: 'Gagal menambah log: $e');
    }
  }
}
