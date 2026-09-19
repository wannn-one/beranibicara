import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/admin/domain/entities/managed_profile.dart';
import 'package:beranibicara/features/admin/domain/repositories/admin_repository.dart';

class UpdateStudentKelasUseCase {
  final AdminRepository repository;

  UpdateStudentKelasUseCase(this.repository);

  Future<Either<Failure, ManagedProfile>> call({
    required String userId,
    required int? kelasId,
  }) {
    return repository.updateStudentKelas(userId: userId, kelasId: kelasId);
  }
}
