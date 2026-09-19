import 'dart:io';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/core/errors/exceptions.dart';
import 'package:beranibicara/features/socialization/data/models/socialization_model.dart';

class SocializationRemoteDataSource {
  final SupabaseClient supabaseClient;

  SocializationRemoteDataSource(this.supabaseClient);

  static const _select = '''
    id, author_id, title, content, cover_image_url, created_at, published_at,
    author:profiles!socialization_author_id_fkey(full_name)
  ''';

  Future<List<SocializationModel>> listPublished() async {
    try {
      final response = await supabaseClient
          .from('socialization')
          .select(_select)
          .isFilter('deleted_at', null)
          .not('published_at', 'is', null)
          .order('published_at', ascending: false);
      return (response as List)
          .map(
            (json) =>
                SocializationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal memuat sosialisasi: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Gagal memuat sosialisasi: $e');
    }
  }

  Future<SocializationModel> getById(int id) async {
    try {
      final response = await supabaseClient
          .from('socialization')
          .select(_select)
          .eq('id', id)
          .single();
      return SocializationModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal memuat artikel: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Gagal memuat artikel: $e');
    }
  }

  Future<SocializationModel> create({
    required String authorId,
    required String title,
    required String content,
    required String imagePath,
  }) async {
    try {
      final coverImageUrl = await _uploadCoverImage(
        authorId: authorId,
        imagePath: imagePath,
      );

      final response = await supabaseClient.from('socialization').insert({
        'author_id': authorId,
        'title': title,
        'content': content,
        'cover_image_url': coverImageUrl,
        'published_at': DateTime.now().toUtc().toIso8601String(),
      }).select(_select);

      if (response.isEmpty) {
        throw PermissionException(message: 'Tidak diizinkan membuat sosialisasi');
      }
      return SocializationModel.fromJson(response.first);
    } on PermissionException {
      rethrow;
    } on FileException {
      rethrow;
    } on InvalidFileTypeException {
      rethrow;
    } on FileSizeExceededException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal membuat sosialisasi: ${e.message}');
    } catch (e) {
      if (e is PermissionException ||
          e is FileException ||
          e is InvalidFileTypeException ||
          e is FileSizeExceededException) {
        rethrow;
      }
      throw ServerException(message: 'Gagal membuat sosialisasi: $e');
    }
  }

  Future<SocializationModel> update({
    required int id,
    required String title,
    required String content,
    String? imagePath,
  }) async {
    try {
      final updates = <String, dynamic>{
        'title': title,
        'content': content,
      };
      if (imagePath != null && imagePath.isNotEmpty) {
        final userId = supabaseClient.auth.currentUser?.id ?? 'cover';
        updates['cover_image_url'] = await _uploadCoverImage(
          authorId: userId,
          imagePath: imagePath,
        );
      }

      final response = await supabaseClient
          .from('socialization')
          .update(updates)
          .eq('id', id)
          .select(_select);

      if (response.isEmpty) {
        throw PermissionException(message: 'Tidak diizinkan mengubah sosialisasi');
      }
      return SocializationModel.fromJson(response.first);
    } on PermissionException {
      rethrow;
    } on FileException {
      rethrow;
    } on InvalidFileTypeException {
      rethrow;
    } on FileSizeExceededException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Gagal mengubah sosialisasi: ${e.message}');
    } catch (e) {
      if (e is PermissionException ||
          e is FileException ||
          e is InvalidFileTypeException ||
          e is FileSizeExceededException) {
        rethrow;
      }
      throw ServerException(message: 'Gagal mengubah sosialisasi: $e');
    }
  }

  Future<void> delete(int id) async {
    try {
      await supabaseClient.rpc(
        'soft_delete_socialization',
        params: {'p_content_id': id},
      );
    } on PostgrestException catch (e) {
      if (e.message.toLowerCase().contains('only tppk') ||
          e.message.toLowerCase().contains('not found')) {
        throw PermissionException(message: e.message);
      }
      throw ServerException(message: 'Gagal menghapus sosialisasi: ${e.message}');
    } catch (e) {
      if (e is PermissionException) rethrow;
      throw ServerException(message: 'Gagal menghapus sosialisasi: $e');
    }
  }

  Future<String> _uploadCoverImage({
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
        : 'cover.jpg';
    final safeName = rawName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath =
        '$authorId/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    try {
      await supabaseClient.storage
          .from(AppConstants.bucketSocialization)
          .upload(storagePath, file);
    } catch (e) {
      throw FileException(message: 'Gagal unggah gambar: $e');
    }

    return supabaseClient.storage
        .from(AppConstants.bucketSocialization)
        .getPublicUrl(storagePath);
  }
}
