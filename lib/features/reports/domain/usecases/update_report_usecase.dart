import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';
import 'package:beranibicara/features/reports/domain/repositories/report_repository.dart';

/// Use case for updating a report (student can edit before verification)
class UpdateReportUseCase {
  final ReportRepository repository;

  UpdateReportUseCase(this.repository);

  Future<Either<Failure, Report>> call({
    required String reportId,
    String? title,
    String? description,
    bool? isAnonymous,
  }) async {
    if (reportId.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Report ID tidak valid'));
    }

    // Validation for new fields
    if (title != null && title.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Judul tidak boleh kosong jika diisi'));
    }

    if (description != null && description.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Deskripsi tidak boleh kosong'));
    }

    if (description != null && description.trim().length < 10) {
      return const Left(ValidationFailure(message: 'Deskripsi minimal 10 karakter'));
    }

    return await repository.updateReport(
      reportId: reportId,
      title: title?.trim(),
      description: description?.trim(),
      isAnonymous: isAnonymous,
    );
  }
}
