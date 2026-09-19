import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';
import 'package:beranibicara/features/reports/domain/repositories/report_repository.dart';

/// Use case for updating report status (TPPK only)
/// Note: tahapan is managed in log_penanganan table, not here
class UpdateReportStatusUseCase {
  final ReportRepository repository;

  UpdateReportStatusUseCase(this.repository);

  Future<Either<Failure, Report>> call({
    required String reportId,
    required ReportStatus newStatus,
  }) async {
    if (reportId.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Report ID tidak valid'));
    }

    return await repository.updateReportStatus(
      reportId: reportId,
      newStatus: newStatus,
    );
  }
}
