import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';
import 'package:beranibicara/features/reports/domain/repositories/report_repository.dart';

/// Use case for creating a new report
class CreateReportUseCase {
  final ReportRepository repository;

  CreateReportUseCase(this.repository);

  Future<Either<Failure, Report>> call({
    String? title,
    required String description,
    required bool isAnonymous,
    required String reporterId,
  }) async {
    // Validation
    if (title != null && title.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Judul tidak boleh kosong jika diisi'));
    }

    if (description.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Deskripsi laporan tidak boleh kosong'));
    }

    if (description.trim().length < 10) {
      return const Left(ValidationFailure(message: 'Deskripsi laporan minimal 10 karakter'));
    }

    // Call repository
    return await repository.createReport(
      title: title?.trim(),
      description: description.trim(),
      isAnonymous: isAnonymous,
      reporterId: reporterId,
    );
  }
}
