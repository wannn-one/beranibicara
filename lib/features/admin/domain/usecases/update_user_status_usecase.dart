import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/admin/domain/entities/managed_profile.dart';
import 'package:beranibicara/features/admin/domain/repositories/admin_repository.dart';

class UpdateUserStatusUseCase {
  final AdminRepository repository;

  UpdateUserStatusUseCase(this.repository);

  Future<Either<Failure, ManagedProfile>> call({
    required String actorId,
    required String userId,
    required UserStatus status,
    String? reason,
  }) {
    if (actorId == userId) {
      return Future.value(
        const Left(
          PermissionFailure('Tidak bisa mengubah status akun sendiri'),
        ),
      );
    }
    return repository.updateStatus(
      userId: userId,
      status: status,
      adminId: actorId,
      reason: reason,
    );
  }
}
