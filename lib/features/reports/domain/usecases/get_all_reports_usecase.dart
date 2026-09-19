import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';
import 'package:beranibicara/features/reports/domain/repositories/report_repository.dart';

/// Use case for getting all reports (for TPPK/Admin)
class GetAllReportsUseCase {
  final ReportRepository repository;

  GetAllReportsUseCase(this.repository);

  Future<Either<Failure, List<Report>>> call({
    ReportStatus? status,
    int? limit,
    int? offset,
  }) async {
    return await repository.getAllReports(
      status: status,
      limit: limit,
      offset: offset,
    );
  }
}
