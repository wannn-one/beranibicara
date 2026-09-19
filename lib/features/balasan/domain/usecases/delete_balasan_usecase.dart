import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/balasan/domain/repositories/balasan_repository.dart';

/// Use Case: Delete a reply
/// 
/// Business rules:
/// - Only TPPK who created the reply can delete it
/// - Admin can delete any reply
/// - Students cannot delete replies
class DeleteBalasanUseCase {
  final BalasanRepository repository;

  DeleteBalasanUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required int balasanId,
    required String userId,
  }) async {
    // Validation
    if (balasanId <= 0) {
      return Left(ValidationFailure(message: 'ID balasan tidak valid'));
    }

    if (userId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'User ID tidak valid'));
    }

    return await repository.deleteBalasan(
      balasanId: balasanId,
      userId: userId,
    );
  }
}
