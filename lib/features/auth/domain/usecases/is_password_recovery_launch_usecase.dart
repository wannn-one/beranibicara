import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/auth/domain/repositories/auth_repository.dart';

class IsPasswordRecoveryLaunchUseCase {
  final AuthRepository repository;

  IsPasswordRecoveryLaunchUseCase(this.repository);

  Future<Either<Failure, bool>> call() => repository.isPasswordRecoveryLaunch();
}
