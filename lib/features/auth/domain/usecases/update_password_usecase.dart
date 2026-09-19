import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/auth/domain/repositories/auth_repository.dart';

class UpdatePasswordUseCase {
  final AuthRepository repository;

  UpdatePasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(String password) {
    if (password.length < AppConstants.minPasswordLength) {
      return Future.value(
        Left(
          WeakPasswordFailure(
            'Password minimal ${AppConstants.minPasswordLength} karakter',
          ),
        ),
      );
    }
    return repository.updatePassword(password);
  }
}
