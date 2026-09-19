import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/reports/domain/repositories/report_repository.dart';

/// Use case for deleting a report (soft delete)
class DeleteReportUseCase {
  final ReportRepository repository;

  DeleteReportUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String reportId,
    required String deletedBy,
  }) async {
    if (reportId.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Report ID tidak valid'));
    }

    if (deletedBy.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Deleted by user ID tidak valid'));
    }

    return await repository.deleteReport(
      reportId: reportId,
      deletedBy: deletedBy,
    );
  }
}
