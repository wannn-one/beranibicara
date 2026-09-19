import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/core/errors/exceptions.dart';
import 'package:beranibicara/features/admin/data/models/managed_profile_model.dart';
import 'package:beranibicara/features/admin/data/models/managed_kelas_model.dart';
import 'package:beranibicara/features/admin/domain/entities/admin_stats.dart';

class AdminRemoteDataSource {
  final SupabaseClient supabaseClient;

  AdminRemoteDataSource(this.supabaseClient);

  Future<List<ManagedProfileModel>> listProfiles() async {
    try {
      final response = await supabaseClient
          .from('profiles')
          .select('id, full_name, role, status, nisn, kelas_id, created_at')
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (json) =>
                ManagedProfileModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal memuat pengguna: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Gagal memuat pengguna: $e');
    }
  }

  Future<ManagedProfileModel> updateRole({
    required String userId,
    required String role,
  }) async {
    try {
      final updates = <String, dynamic>{'role': role};
      if (role != 'siswa') {
        updates['nisn'] = null;
      }

      final response = await supabaseClient
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select('id, full_name, role, status, nisn, kelas_id, created_at');

      if (response.isEmpty) {
        throw PermissionException(message: 'Tidak diizinkan mengubah role');
      }
      return ManagedProfileModel.fromJson(response.first);
    } on PermissionException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal mengubah role: ${e.message}');
    } catch (e) {
      if (e is PermissionException) rethrow;
      throw ServerException(message: 'Gagal mengubah role: $e');
    }
  }

  Future<ManagedProfileModel> updateStatus({
    required String userId,
    required String status,
    required String adminId,
    String? reason,
  }) async {
    try {
      final updates = <String, dynamic>{'status': status};
      if (status == 'blocked') {
        updates['blocked_reason'] = (reason == null || reason.trim().isEmpty)
            ? 'Diblokir oleh admin'
            : reason.trim();
        updates['blocked_by'] = adminId;
        updates['blocked_at'] = DateTime.now().toUtc().toIso8601String();
      } else {
        updates['blocked_reason'] = null;
        updates['blocked_by'] = null;
        updates['blocked_at'] = null;
        updates['blocked_until'] = null;
      }

      final response = await supabaseClient
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select('id, full_name, role, status, nisn, kelas_id, created_at');

      if (response.isEmpty) {
        throw PermissionException(message: 'Tidak diizinkan mengubah status');
      }
      return ManagedProfileModel.fromJson(response.first);
    } on PermissionException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal mengubah status: ${e.message}');
    } catch (e) {
      if (e is PermissionException) rethrow;
      throw ServerException(message: 'Gagal mengubah status: $e');
    }
  }

  static const _kelasSelect =
      'id, tingkat, jurusan, wali_kelas_id, wali:profiles!kelas_wali_kelas_id_fkey(full_name)';

  Future<List<ManagedKelasModel>> listKelas() async {
    try {
      final response = await supabaseClient
          .from('kelas')
          .select(_kelasSelect)
          .order('tingkat')
          .order('jurusan');

      return (response as List)
          .map(
            (json) => ManagedKelasModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal memuat kelas: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Gagal memuat kelas: $e');
    }
  }

  Future<ManagedKelasModel> createKelas({
    required int tingkat,
    required String jurusan,
  }) async {
    try {
      final response = await supabaseClient
          .from('kelas')
          .insert({'tingkat': tingkat, 'jurusan': jurusan})
          .select(_kelasSelect);

      if (response.isEmpty) {
        throw PermissionException(message: 'Tidak diizinkan menambah kelas');
      }
      return ManagedKelasModel.fromJson(response.first);
    } on PermissionException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal menambah kelas: ${e.message}');
    } catch (e) {
      if (e is PermissionException) rethrow;
      throw ServerException(message: 'Gagal menambah kelas: $e');
    }
  }

  Future<ManagedKelasModel> assignWaliKelas({
    required int kelasId,
    required String? waliKelasId,
  }) async {
    try {
      final response = await supabaseClient
          .from('kelas')
          .update({'wali_kelas_id': waliKelasId})
          .eq('id', kelasId)
          .select(_kelasSelect);

      if (response.isEmpty) {
        throw PermissionException(message: 'Tidak diizinkan mengubah wali kelas');
      }
      return ManagedKelasModel.fromJson(response.first);
    } on PermissionException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal mengubah wali kelas: ${e.message}');
    } catch (e) {
      if (e is PermissionException) rethrow;
      throw ServerException(message: 'Gagal mengubah wali kelas: $e');
    }
  }

  Future<ManagedProfileModel> updateStudentKelas({
    required String userId,
    required int? kelasId,
  }) async {
    try {
      final response = await supabaseClient
          .from('profiles')
          .update({'kelas_id': kelasId})
          .eq('id', userId)
          .select('id, full_name, role, status, nisn, kelas_id, created_at');

      if (response.isEmpty) {
        throw PermissionException(message: 'Tidak diizinkan mengubah kelas siswa');
      }
      return ManagedProfileModel.fromJson(response.first);
    } on PermissionException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal mengubah kelas: ${e.message}');
    } catch (e) {
      if (e is PermissionException) rethrow;
      throw ServerException(message: 'Gagal mengubah kelas: $e');
    }
  }

  Future<AdminStats> getStats() async {
    try {
      final profiles = await supabaseClient
          .from('profiles')
          .select('role, status');
      final reports = await supabaseClient
          .from('reports')
          .select('status')
          .isFilter('deleted_at', null);
      final kelas = await supabaseClient.from('kelas').select('id');
      final socialization = await supabaseClient
          .from('socialization')
          .select('id')
          .isFilter('deleted_at', null);

      final profileRows = List<dynamic>.from(profiles as List);
      final reportRows = List<dynamic>.from(reports as List);
      final kelasRows = List<dynamic>.from(kelas as List);
      final socializationRows = List<dynamic>.from(socialization as List);

      var siswa = 0, guru = 0, tppk = 0, admin = 0, aktif = 0, blocked = 0;
      for (final row in profileRows) {
        final map = row as Map<String, dynamic>;
        switch (map['role'] as String?) {
          case 'guru':
            guru++;
          case 'tppk':
            tppk++;
          case 'admin':
            admin++;
          default:
            siswa++;
        }
        if (map['status'] == 'blocked') {
          blocked++;
        } else if (map['status'] == 'aktif') {
          aktif++;
        }
      }

      final reportsByStatus = <String, int>{};
      for (final row in reportRows) {
        final status =
            (row as Map<String, dynamic>)['status'] as String? ?? 'baru';
        reportsByStatus[status] = (reportsByStatus[status] ?? 0) + 1;
      }

      return AdminStats(
        usersTotal: profileRows.length,
        usersSiswa: siswa,
        usersGuru: guru,
        usersTppk: tppk,
        usersAdmin: admin,
        usersAktif: aktif,
        usersBlocked: blocked,
        kelasTotal: kelasRows.length,
        reportsTotal: reportRows.length,
        reportsByStatus: reportsByStatus,
        socializationTotal: socializationRows.length,
      );
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal memuat statistik: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Gagal memuat statistik: $e');
    }
  }
}
