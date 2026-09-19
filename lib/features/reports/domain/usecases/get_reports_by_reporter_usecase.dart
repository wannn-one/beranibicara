import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';
import 'package:beranibicara/features/reports/domain/repositories/report_repository.dart';

/// Use case for getting reports by reporter (for students to see their own reports)
class GetReportsByReporterUseCase {
  final ReportRepository repository;

  GetReportsByReporterUseCase(this.repository);

  Future<Either<Failure, List<Report>>> call(String reporterId) async {
    if (reporterId.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Reporter ID tidak valid'));
    }

    return await repository.getReportsByReporter(reporterId);
  }
}
