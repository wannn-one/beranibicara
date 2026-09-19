import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';
import 'package:beranibicara/features/log_penanganan/domain/entities/log_penanganan.dart';
import 'package:beranibicara/features/log_penanganan/domain/repositories/log_penanganan_repository.dart';

class CreateLogPenangananUseCase {
  final LogPenangananRepository repository;

  CreateLogPenangananUseCase(this.repository);

  Future<Either<Failure, LogPenanganan>> call({
    required int reportId,
    required String authorId,
    required String catatan,
    required TahapanType tahapan,
  }) async {
    final trimmed = catatan.trim();
    if (trimmed.length < 10) {
      return const Left(
        ValidationFailure(message: 'Catatan minimal 10 karakter'),
      );
    }

    return repository.create(
      reportId: reportId,
      authorId: authorId,
      catatan: trimmed,
      tahapan: tahapan,
    );
  }
}
