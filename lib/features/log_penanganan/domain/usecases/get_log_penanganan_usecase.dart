import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/log_penanganan/domain/entities/log_penanganan.dart';
import 'package:beranibicara/features/log_penanganan/domain/repositories/log_penanganan_repository.dart';

class GetLogPenangananUseCase {
  final LogPenangananRepository repository;

  GetLogPenangananUseCase(this.repository);

  Future<Either<Failure, List<LogPenanganan>>> call(int reportId) {
    if (reportId <= 0) {
      return Future.value(
        const Left(ValidationFailure(message: 'ID laporan tidak valid')),
      );
    }
    return repository.getByReportId(reportId);
  }
}
