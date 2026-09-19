import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';
import 'package:beranibicara/features/reports/domain/repositories/report_repository.dart';

/// Use case for getting a report by ID
class GetReportByIdUseCase {
  final ReportRepository repository;

  GetReportByIdUseCase(this.repository);

  Future<Either<Failure, Report>> call(String reportId) async {
    if (reportId.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Report ID tidak valid'));
    }

    return await repository.getReportById(reportId);
  }
}
