import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/balasan/domain/entities/balasan_laporan.dart';
import 'package:beranibicara/features/balasan/domain/repositories/balasan_repository.dart';

/// Use Case: Get all replies for a specific report
/// 
/// Business rules:
/// - Report ID must be valid (> 0)
/// - Returns replies ordered by created_at ASC (oldest first)
/// - Students can only see replies for their own reports
/// - TPPK/Admin can see all replies
class GetBalasanByReportIdUseCase {
  final BalasanRepository repository;

  GetBalasanByReportIdUseCase(this.repository);

  Future<Either<Failure, List<BalasanLaporan>>> call(int reportId) async {
    // Validation
    if (reportId <= 0) {
      return Left(ValidationFailure(message: 'ID laporan tidak valid'));
    }

    return await repository.getBalasanByReportId(reportId);
  }
}
