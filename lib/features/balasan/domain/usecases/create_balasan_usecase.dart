import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/balasan/domain/entities/balasan_laporan.dart';
import 'package:beranibicara/features/balasan/domain/repositories/balasan_repository.dart';

/// Use Case: Create a new reply to a report
/// 
/// Business rules:
/// - Message must not be empty
/// - Message must be at least 1 character
/// - Message must not exceed 5000 characters
/// - Only TPPK can create replies (enforced by RLS)
class CreateBalasanUseCase {
  final BalasanRepository repository;

  CreateBalasanUseCase(this.repository);

  Future<Either<Failure, BalasanLaporan>> call({
    required int reportId,
    required String authorId,
    required String pesan,
  }) async {
    // Validation
    if (pesan.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Pesan tidak boleh kosong'));
    }

    if (pesan.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Pesan terlalu pendek'));
    }

    if (pesan.length > 5000) {
      return Left(ValidationFailure(message: 'Pesan terlalu panjang (maksimal 5000 karakter)'));
    }

    return await repository.createBalasan(
      reportId: reportId,
      authorId: authorId,
      pesan: pesan.trim(),
    );
  }
}
