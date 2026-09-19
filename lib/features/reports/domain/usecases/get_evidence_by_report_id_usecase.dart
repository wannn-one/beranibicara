import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/reports/domain/entities/evidence.dart';
import 'package:beranibicara/features/reports/domain/repositories/report_repository.dart';

/// Get evidence files for a report
class GetEvidenceByReportIdUseCase {
  final ReportRepository repository;

  GetEvidenceByReportIdUseCase(this.repository);

  Future<Either<Failure, List<Evidence>>> call(String reportId) async {
    if (reportId.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Report ID tidak valid'));
    }

    return await repository.getEvidenceByReportId(reportId);
  }
}
