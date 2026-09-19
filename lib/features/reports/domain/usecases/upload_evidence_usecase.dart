import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/reports/domain/entities/evidence.dart';
import 'package:beranibicara/features/reports/domain/repositories/report_repository.dart';

/// Upload evidence files for an existing report
class UploadEvidenceUseCase {
  final ReportRepository repository;

  UploadEvidenceUseCase(this.repository);

  Future<Either<Failure, List<Evidence>>> call({
    required String reportId,
    required List<String> filePaths,
  }) async {
    if (reportId.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Report ID tidak valid'));
    }

    if (filePaths.isEmpty) {
      return const Right([]);
    }

    if (filePaths.length > 3) {
      return const Left(
        ValidationFailure(message: 'Maksimal 3 file bukti per laporan'),
      );
    }

    return await repository.uploadEvidenceFiles(
      reportId: reportId,
      filePaths: filePaths,
    );
  }
}
