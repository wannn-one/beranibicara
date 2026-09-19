import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/auth/domain/repositories/auth_repository.dart';

/// Reset Password Use Case
/// Sends password reset email
class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(String email) async {
    // Validate email
    if (email.isEmpty) {
      return const Left(InvalidEmailFailure('Email is required'));
    }

    if (!_isValidEmail(email)) {
      return const Left(InvalidEmailFailure('Invalid email format'));
    }

    return await repository.resetPassword(email);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
