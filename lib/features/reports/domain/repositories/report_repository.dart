import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';
import 'package:beranibicara/features/reports/domain/entities/evidence.dart';

/// Abstract repository interface for reports
/// Following Clean Architecture, this defines the contract that data layer must implement
abstract class ReportRepository {
  /// Create a new report
  /// Returns Either&lt;Failure, Report&gt; - Left for errors, Right for success
  Future<Either<Failure, Report>> createReport({
    String? title,
    required String description,
    required bool isAnonymous,
    required String reporterId,
  });

  /// Get report by ID
  Future<Either<Failure, Report>> getReportById(String reportId);

  /// Get all reports for a specific user (reporter)
  Future<Either<Failure, List<Report>>> getReportsByReporter(String reporterId);

  /// Get all reports for TPPK/Admin (with optional filters)
  Future<Either<Failure, List<Report>>> getAllReports({
    ReportStatus? status,
    int? limit,
    int? offset,
  });

  /// Update report status (TPPK only)
  /// Note: tahapan is NOT updated here - it's managed via log_penanganan table
  Future<Either<Failure, Report>> updateReportStatus({
    required String reportId,
    required ReportStatus newStatus,
  });

  /// Update report (reporter can edit before verification)
  Future<Either<Failure, Report>> updateReport({
    required String reportId,
    String? title,
    String? description,
    bool? isAnonymous,
  });

  /// Soft delete report (sets deleted_at and deleted_by)
  Future<Either<Failure, void>> deleteReport({
    required String reportId,
    required String deletedBy,
  });

  // === Evidence Management ===

  /// Upload evidence files for a report
  /// Returns list of created Evidence entities
  Future<Either<Failure, List<Evidence>>> uploadEvidenceFiles({
    required String reportId,
    required List<String> filePaths,
  });

  /// Get all evidence for a report
  Future<Either<Failure, List<Evidence>>> getEvidenceByReportId(String reportId);

  /// Delete evidence file
  Future<Either<Failure, void>> deleteEvidence(String evidenceId);
}
