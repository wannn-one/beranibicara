import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/reports/domain/repositories/report_repository.dart';

class DeleteEvidenceUseCase {
  final ReportRepository repository;

  DeleteEvidenceUseCase(this.repository);

  Future<Either<Failure, void>> call(String evidenceId) async {
    if (evidenceId.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'ID lampiran tidak valid'));
    }

    return await repository.deleteEvidence(evidenceId);
  }
}
