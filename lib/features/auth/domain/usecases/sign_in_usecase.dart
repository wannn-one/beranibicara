import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/auth/domain/repositories/auth_repository.dart';

/// Sign In Use Case
/// Handles email/password authentication
class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<Either<Failure, User>> call({
    required String email,
    required String password,
  }) async {
    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Email and password are required'),
      );
    }

    // Basic email format validation
    if (!_isValidEmail(email)) {
      return const Left(InvalidEmailFailure('Invalid email format'));
    }

    // Call repository
    return await repository.signIn(email: email, password: password);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
