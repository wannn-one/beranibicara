import 'dart:io';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/core/errors/exceptions.dart';
import 'package:beranibicara/features/cerita_kelas/data/models/cerita_kelas_model.dart';
import 'package:beranibicara/features/cerita_kelas/data/models/tanggapan_cerita_model.dart';
import 'package:beranibicara/features/cerita_kelas/domain/entities/wali_kelas_option.dart';

class CeritaKelasRemoteDataSource {
  final SupabaseClient supabaseClient;

  CeritaKelasRemoteDataSource(this.supabaseClient);

  static const _storySelect = '''
    id, author_id, kelas_id, judul, konten, gambar_url, is_published, created_at,
    author:profiles!cerita_kelas_author_id_fkey(full_name)
  ''';

  static const _commentSelect = '''
    id, cerita_id, author_id, tanggapan, created_at,
    author:profiles!tanggapan_cerita_author_id_fkey(full_name)
  ''';

  Future<List<CeritaKelasModel>> list({
    int? kelasId,
    List<int>? kelasIds,
  }) async {
    try {
      dynamic query = supabaseClient
          .from('cerita_kelas')
          .select(_storySelect)
          .isFilter('deleted_at', null)
          .eq('is_published', true);

      if (kelasId != null) {
        query = query.eq('kelas_id', kelasId);
      } else if (kelasIds != null) {
        if (kelasIds.isEmpty) return [];
        query = query.inFilter('kelas_id', kelasIds);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((json) => CeritaKelasModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal memuat cerita: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Gagal memuat cerita: $e');
    }
  }

  Future<CeritaKelasModel> getById(int id) async {
    try {
      final response = await supabaseClient
          .from('cerita_kelas')
          .select(_storySelect)
          .eq('id', id)
          .isFilter('deleted_at', null)
          .single();
      return CeritaKelasModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal memuat cerita: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Gagal memuat cerita: $e');
    }
  }

  Future<CeritaKelasModel> create({
    required String authorId,
    required int kelasId,
    required String judul,
    required String konten,
    String? imagePath,
  }) async {
    try {
      String? gambarUrl;
      if (imagePath != null && imagePath.isNotEmpty) {
        gambarUrl = await _uploadImage(authorId: authorId, imagePath: imagePath);
      }

      final payload = <String, dynamic>{
        'author_id': authorId,
        'kelas_id': kelasId,
        'judul': judul,
        'konten': konten,
        'is_published': true,
      };
      if (gambarUrl != null) payload['gambar_url'] = gambarUrl;

      final response =
          await supabaseClient.from('cerita_kelas').insert(payload).select(_storySelect);

      if (response.isEmpty) {
        throw PermissionException(message: 'Tidak diizinkan membuat cerita kelas');
      }
      return CeritaKelasModel.fromJson(response.first);
    } on PermissionException {
      rethrow;
    } on FileException {
      rethrow;
    } on InvalidFileTypeException {
      rethrow;
    } on FileSizeExceededException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal membuat cerita: ${e.message}');
    } catch (e) {
      if (e is PermissionException ||
          e is FileException ||
          e is InvalidFileTypeException ||
          e is FileSizeExceededException) {
        rethrow;
      }
      throw ServerException(message: 'Gagal membuat cerita: $e');
    }
  }

  Future<CeritaKelasModel> update({
    required int id,
    required String judul,
    required String konten,
    String? imagePath,
  }) async {
    try {
      final updates = <String, dynamic>{
        'judul': judul,
        'konten': konten,
      };
      if (imagePath != null && imagePath.isNotEmpty) {
        final userId = supabaseClient.auth.currentUser?.id ?? 'story';
        updates['gambar_url'] =
            await _uploadImage(authorId: userId, imagePath: imagePath);
      }

      final response = await supabaseClient
          .from('cerita_kelas')
          .update(updates)
          .eq('id', id)
          .select(_storySelect);

      if (response.isEmpty) {
        throw PermissionException(message: 'Tidak diizinkan mengubah cerita');
      }
      return CeritaKelasModel.fromJson(response.first);
    } on PermissionException {
      rethrow;
    } on FileException {
      rethrow;
    } on InvalidFileTypeException {
      rethrow;
    } on FileSizeExceededException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal mengubah cerita: ${e.message}');
    } catch (e) {
      if (e is PermissionException ||
          e is FileException ||
          e is InvalidFileTypeException ||
          e is FileSizeExceededException) {
        rethrow;
      }
      throw ServerException(message: 'Gagal mengubah cerita: $e');
    }
  }

  Future<void> delete(int id) async {
    try {
      await supabaseClient.rpc(
        'soft_delete_story',
        params: {'p_story_id': id},
      );
    } on PostgrestException catch (e) {
      if (e.message.toLowerCase().contains('not authorized') ||
          e.message.toLowerCase().contains('not found')) {
        throw PermissionException(message: e.message);
      }
      throw ServerException(message: 'Gagal menghapus cerita: ${e.message}');
    } catch (e) {
      if (e is PermissionException) rethrow;
      throw ServerException(message: 'Gagal menghapus cerita: $e');
    }
  }

  Future<List<TanggapanCeritaModel>> listComments(int ceritaId) async {
    try {
      final response = await supabaseClient
          .from('tanggapan_cerita')
          .select(_commentSelect)
          .eq('cerita_id', ceritaId)
          .order('created_at', ascending: true);
      return (response as List)
          .map(
            (json) =>
                TanggapanCeritaModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal memuat tanggapan: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Gagal memuat tanggapan: $e');
    }
  }

  Future<TanggapanCeritaModel> addComment({
    required int ceritaId,
    required String authorId,
    required String tanggapan,
  }) async {
    try {
      final response = await supabaseClient.from('tanggapan_cerita').insert({
        'cerita_id': ceritaId,
        'author_id': authorId,
        'tanggapan': tanggapan,
      }).select(_commentSelect);

      if (response.isEmpty) {
        throw PermissionException(message: 'Tidak diizinkan menambah tanggapan');
      }
      return TanggapanCeritaModel.fromJson(response.first);
    } on PermissionException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal menambah tanggapan: ${e.message}');
    } catch (e) {
      if (e is PermissionException) rethrow;
      throw ServerException(message: 'Gagal menambah tanggapan: $e');
    }
  }

  Future<void> deleteComment(int id) async {
    try {
      final response = await supabaseClient
          .from('tanggapan_cerita')
          .delete()
          .eq('id', id)
          .select('id');
      if (response.isEmpty) {
        throw PermissionException(message: 'Tidak diizinkan menghapus tanggapan');
      }
    } on PermissionException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal menghapus tanggapan: ${e.message}');
    } catch (e) {
      if (e is PermissionException) rethrow;
      throw ServerException(message: 'Gagal menghapus tanggapan: $e');
    }
  }

  Future<List<WaliKelasOption>> listWaliKelas(String userId) async {
    try {
      final response = await supabaseClient
          .from('kelas')
          .select('id, tingkat, jurusan')
          .eq('wali_kelas_id', userId)
          .order('tingkat')
          .order('jurusan');
      return (response as List).map((json) {
        final map = json as Map<String, dynamic>;
        return WaliKelasOption(
          id: map['id'] as int,
          tingkat: map['tingkat'] as int,
          jurusan: map['jurusan'] as String,
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal memuat kelas: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Gagal memuat kelas: $e');
    }
  }

  Future<String> _uploadImage({
    required String authorId,
    required String imagePath,
  }) async {
    final file = File(imagePath);
    if (!file.existsSync()) {
      throw FileException(message: 'Gambar tidak ditemukan');
    }
    final fileSize = file.lengthSync();
    if (fileSize > AppConstants.maxFileSize) {
      throw FileSizeExceededException(message: 'Gambar maksimal 10MB');
    }
    final mimeType = lookupMimeType(imagePath);
    if (mimeType == null || !mimeType.startsWith('image/')) {
      throw InvalidFileTypeException(message: 'Hanya file gambar yang diizinkan');
    }
    final rawName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'cerita.jpg';
    final safeName = rawName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath =
        '$authorId/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    try {
      await supabaseClient.storage
          .from(AppConstants.bucketCeritaKelas)
          .upload(storagePath, file);
    } catch (e) {
      throw FileException(message: 'Gagal unggah gambar: $e');
    }

    return supabaseClient.storage
        .from(AppConstants.bucketCeritaKelas)
        .getPublicUrl(storagePath);
  }
}
