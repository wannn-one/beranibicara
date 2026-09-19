import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import 'package:beranibicara/core/errors/exceptions.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/features/reports/data/models/report_model.dart';
import 'package:beranibicara/features/reports/data/models/evidence_model.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';
import 'package:mime/mime.dart';

/// Remote data source for reports and evidence
/// Handles all Supabase operations for reports and evidence tables
class ReportRemoteDataSource {
  final supabase_flutter.SupabaseClient supabaseClient;

  ReportRemoteDataSource(this.supabaseClient);

  static const _reportSelect =
      '*, reporter:profiles!reports_reporter_id_fkey(full_name)';

  // ===================================================================
  // REPORTS CRUD OPERATIONS
  // ===================================================================

  /// Create a new report
  Future<ReportModel> createReport({
    String? title,
    required String description,
    required bool isAnonymous,
    required String reporterId,
  }) async {
    try {
      final response = await supabaseClient
          .from('reports')
          .insert({
            'title': title,
            'description': description,
            'is_anonymous': isAnonymous,
            'reporter_id': reporterId,
            'status': 'baru',
          })
          .select(_reportSelect)
          .single();

      return ReportModel.fromJson(response);
    } on supabase_flutter.PostgrestException catch (e) {
      throw ServerException(
        message: 'Failed to create report: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  /// Get report by ID
  Future<ReportModel> getReportById(String reportId) async {
    try {
      final response = await supabaseClient
          .from('reports')
          .select(_reportSelect)
          .eq('id', reportId)
          .isFilter('deleted_at', null)
          .single();

      return ReportModel.fromJson(response);
    } on supabase_flutter.PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw NotFoundException(message: 'Report not found');
      }
      throw ServerException(
        message: 'Failed to fetch report: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  /// Get reports by reporter
  Future<List<ReportModel>> getReportsByReporter(String reporterId) async {
    try {
      final response = await supabaseClient
          .from('reports')
          .select(_reportSelect)
          .eq('reporter_id', reporterId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ReportModel.fromJson(json))
          .toList();
    } on supabase_flutter.PostgrestException catch (e) {
      throw ServerException(
        message: 'Failed to fetch reports: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  /// Get all reports with optional filters (for TPPK/Admin)
  Future<List<ReportModel>> getAllReports({
    ReportStatus? status,
    int? limit,
    int? offset,
  }) async {
    try {
      // Build query dynamically
      dynamic query = supabaseClient.from('reports').select(_reportSelect);

      // Filter out soft-deleted reports
      query = query.isFilter('deleted_at', null);

      // Apply filters
      if (status != null) {
        query = query.eq('status', status.value);
      }

      // Order by created_at descending (before pagination)
      query = query.order('created_at', ascending: false);

      // Apply pagination
      if (limit != null) {
        if (offset != null) {
          query = query.range(offset, offset + limit - 1);
        } else {
          query = query.limit(limit);
        }
      }

      final response = await query;

      return (response as List)
          .map((json) => ReportModel.fromJson(json))
          .toList();
    } on supabase_flutter.PostgrestException catch (e) {
      throw ServerException(
        message: 'Failed to fetch reports: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  /// Update report status
  Future<ReportModel> updateReportStatus({
    required String reportId,
    required ReportStatus newStatus,
  }) async {
    try {
      final response = await supabaseClient
          .from('reports')
          .update({
            'status': newStatus.value,
          })
          .eq('id', reportId)
          .select(_reportSelect)
          .single();

      return ReportModel.fromJson(response);
    } on supabase_flutter.PostgrestException catch (e) {
      throw ServerException(
        message: 'Failed to update report status: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  /// Update report
  Future<ReportModel> updateReport({
    required String reportId,
    String? title,
    String? description,
    bool? isAnonymous,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (isAnonymous != null) updateData['is_anonymous'] = isAnonymous;

      if (updateData.isEmpty) {
        throw ValidationException('No fields to update');
      }

      final response = await supabaseClient
          .from('reports')
          .update(updateData)
          .eq('id', reportId)
          .select(_reportSelect)
          .single();

      return ReportModel.fromJson(response);
    } on supabase_flutter.PostgrestException catch (e) {
      throw ServerException(
        message: 'Failed to update report: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  /// Soft delete report (sets deleted_at and deleted_by)
  Future<void> deleteReport({
    required String reportId,
    required String deletedBy,
  }) async {
    try {
      final response = await supabaseClient
          .from('reports')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'deleted_by': deletedBy,
          })
          .eq('id', reportId)
          .isFilter('deleted_at', null)
          .select('id');

      if (response.isEmpty) {
        throw PermissionException(
          message:
              'Tidak bisa menghapus laporan. Periksa izin atau status laporan.',
        );
      }
    } on PermissionException {
      rethrow;
    } on supabase_flutter.PostgrestException catch (e) {
      throw ServerException(
        message: 'Failed to delete report: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  // ===================================================================
  // EVIDENCE CRUD OPERATIONS
  // ===================================================================

  /// Upload evidence files for a report
  /// Returns list of EvidenceModel
  Future<List<EvidenceModel>> uploadEvidenceFiles({
    required String reportId,
    required List<String> filePaths,
  }) async {
    try {
      // Validate file count (max 3)
      if (filePaths.length > 3) {
        throw FileSizeExceededException(
            message: 'Maximum 3 files allowed per report');
      }

      final List<EvidenceModel> evidenceList = [];

      for (final filePath in filePaths) {
        final file = File(filePath);

        // Validate file exists
        if (!file.existsSync()) {
          throw FileException(message: 'File not found: $filePath');
        }

        // Validate file size (max 10MB)
        final fileSize = file.lengthSync();
        const maxSize = 10 * 1024 * 1024; // 10 MB
        if (fileSize > maxSize) {
          throw FileSizeExceededException(
              message: 'File size exceeds 10MB: ${file.path}');
        }

        // Get file type
        final mimeType = lookupMimeType(filePath);
        if (mimeType == null) {
          throw InvalidFileTypeException(message: 'Unknown file type');
        }

        String fileType;
        if (mimeType.startsWith('image/')) {
          fileType = 'image';
        } else if (mimeType.startsWith('video/')) {
          fileType = 'video';
        } else if (mimeType.startsWith('audio/')) {
          fileType = 'audio';
        } else {
          fileType = 'document';
        }

        // Validate file type
        if (!['image', 'video'].contains(fileType)) {
          throw InvalidFileTypeException(
              message: 'Only image and video files are allowed');
        }

        // Upload to Supabase Storage
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
        final storagePath = 'bukti_laporan/$reportId/$fileName';

        await supabaseClient.storage
            .from(AppConstants.bucketReportEvidence)
            .upload(storagePath, file);

        // Get public URL
        final fileUrl = supabaseClient.storage
            .from(AppConstants.bucketReportEvidence)
            .getPublicUrl(storagePath);

        // Insert evidence record into database
        final response = await supabaseClient
            .from('evidence')
            .insert({
              'report_id': reportId,
              'file_url': fileUrl,
              'file_type': fileType,
            })
            .select()
            .single();

        evidenceList.add(EvidenceModel.fromJson(response));
      }

      return evidenceList;
    } on supabase_flutter.PostgrestException catch (e) {
      throw ServerException(
        message: 'Failed to upload evidence: ${e.message}',
        code: e.code,
      );
    } on supabase_flutter.StorageException catch (e) {
      throw FileUploadException(message: 'Failed to upload file: ${e.message}');
    } catch (e) {
      if (e is FileException ||
          e is FileSizeExceededException ||
          e is InvalidFileTypeException ||
          e is FileUploadException) {
        rethrow;
      }
      throw FileException(message: 'Unexpected error: $e');
    }
  }

  /// Get all evidence for a report
  Future<List<EvidenceModel>> getEvidenceByReportId(String reportId) async {
    try {
      final response = await supabaseClient
          .from('evidence')
          .select()
          .eq('report_id', reportId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => EvidenceModel.fromJson(json))
          .toList();
    } on supabase_flutter.PostgrestException catch (e) {
      throw ServerException(
        message: 'Failed to fetch evidence: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  /// Delete evidence (removes from DB and Storage)
  Future<void> deleteEvidence(String evidenceId) async {
    try {
      // First, get the evidence record to get the file URL
      final response = await supabaseClient
          .from('evidence')
          .select()
          .eq('id', evidenceId)
          .single();

      final evidence = EvidenceModel.fromJson(response);

      // Delete from storage
      final fileUrl = evidence.fileUrl;
      final storageUrl = supabaseClient.storage
          .from(AppConstants.bucketReportEvidence)
          .getPublicUrl('');
      
      if (fileUrl.startsWith(storageUrl)) {
        final filePath = fileUrl.substring(storageUrl.length);
        try {
          await supabaseClient.storage
              .from(AppConstants.bucketReportEvidence)
              .remove([filePath]);
        } catch (e) {
          // Silent fail - file might already be deleted
        }
      }

      final deleted = await supabaseClient
          .from('evidence')
          .delete()
          .eq('id', evidenceId)
          .select('id');

      if (deleted.isEmpty) {
        throw PermissionException(
          message: 'Tidak diizinkan menghapus lampiran ini',
        );
      }
    } on supabase_flutter.PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw NotFoundException(message: 'Evidence not found');
      }
      throw ServerException(
        message: 'Failed to delete evidence: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      if (e is NotFoundException) rethrow;
      if (e is PermissionException) rethrow;
      throw FileException(message: 'Unexpected error: $e');
    }
  }
}
