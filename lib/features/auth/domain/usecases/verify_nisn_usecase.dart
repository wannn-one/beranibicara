import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/auth/domain/entities/nisn_registry.dart';
import 'package:beranibicara/features/auth/domain/repositories/auth_repository.dart';
import 'package:beranibicara/core/constants/app_constants.dart';

/// Verify NISN Use Case
/// Validates NISN against the registry
class VerifyNisnUseCase {
  final AuthRepository repository;

  VerifyNisnUseCase(this.repository);

  Future<Either<Failure, NisnRegistry>> call(String nisn) async {
    // Validate NISN format
    if (nisn.isEmpty) {
      return const Left(InvalidNisnFailure('NISN cannot be empty'));
    }

    if (nisn.length != AppConstants.nisnLength) {
      return Left(InvalidNisnFailure(
        'NISN must be exactly ${AppConstants.nisnLength} digits',
      ));
    }

    // Check if all characters are digits
    if (!RegExp(r'^\d+$').hasMatch(nisn)) {
      return const Left(InvalidNisnFailure('NISN must contain only numbers'));
    }

    // Call repository to verify
    return await repository.verifyNisn(nisn);
  }
}
