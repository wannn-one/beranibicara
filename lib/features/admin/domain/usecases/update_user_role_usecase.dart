import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/admin/domain/entities/managed_profile.dart';
import 'package:beranibicara/features/admin/domain/repositories/admin_repository.dart';

class UpdateUserRoleUseCase {
  final AdminRepository repository;

  UpdateUserRoleUseCase(this.repository);

  Future<Either<Failure, ManagedProfile>> call({
    required String actorId,
    required String userId,
    required UserRole role,
  }) {
    if (actorId == userId) {
      return Future.value(
        const Left(
          PermissionFailure('Tidak bisa mengubah role akun sendiri'),
        ),
      );
    }
    return repository.updateRole(userId: userId, role: role);
  }
}
