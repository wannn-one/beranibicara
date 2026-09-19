import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/auth/domain/repositories/auth_repository.dart';

/// Update Profile Use Case
/// Updates user profile information
class UpdateProfileUseCase {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<Either<Failure, User>> call({
    required String userId,
    String? fullName,
    int? kelasId,
    String? nisn,
  }) async {
    // Validate that at least one field is being updated
    if (fullName == null && kelasId == null && nisn == null) {
      return const Left(ValidationFailure(message: 'No fields to update'));
    }

    // Validate full name if provided
    if (fullName != null && fullName.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Full name cannot be empty'),
      );
    }

    return await repository.updateProfile(
      userId: userId,
      fullName: fullName,
      kelasId: kelasId,
      nisn: nisn,
    );
  }
}
