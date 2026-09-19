import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/auth/domain/entities/sign_up_result.dart';
import 'package:beranibicara/features/auth/domain/repositories/auth_repository.dart';
import 'package:beranibicara/core/constants/app_constants.dart';

/// Sign Up Use Case
/// Handles user registration with NISN verification support
class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<Either<Failure, SignUpResult>> call({
    required String email,
    required String password,
    required String fullName,
    UserRole role = UserRole.siswa,
    String? nisn,
  }) async {
    // Validate inputs
    if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
      return const Left(ValidationFailure(message: 'All fields are required'));
    }

    // Validate email format
    if (!_isValidEmail(email)) {
      return const Left(InvalidEmailFailure('Invalid email format'));
    }

    // Validate password length
    if (password.length < AppConstants.minPasswordLength) {
      return Left(WeakPasswordFailure(
        'Password must be at least ${AppConstants.minPasswordLength} characters',
      ));
    }

    if (role != UserRole.siswa && role != UserRole.guru) {
      return const Left(
        ValidationFailure(message: 'Hanya siswa atau guru yang dapat mendaftar'),
      );
    }

    if (role == UserRole.siswa) {
      if (nisn == null || nisn.isEmpty) {
        return const Left(
          ValidationFailure(message: 'NISN wajib diisi untuk siswa'),
        );
      }
      if (nisn.length != AppConstants.nisnLength) {
        return Left(InvalidNisnFailure(
          'NISN must be exactly ${AppConstants.nisnLength} digits',
        ));
      }

      final nisnVerification = await repository.verifyNisn(nisn);

      return nisnVerification.fold(
        (failure) => Left(failure),
        (nisnRegistry) {
          if (!nisnRegistry.isAvailable) {
            return const Left(NisnAlreadyUsedFailure());
          }
          return repository.signUp(
            email: email,
            password: password,
            fullName: fullName,
            role: role,
            nisn: nisn,
          );
        },
      );
    }

    return repository.signUp(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
