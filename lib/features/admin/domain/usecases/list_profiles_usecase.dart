import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/admin/domain/entities/managed_profile.dart';
import 'package:beranibicara/features/admin/domain/repositories/admin_repository.dart';

class ListProfilesUseCase {
  final AdminRepository repository;

  ListProfilesUseCase(this.repository);

  Future<Either<Failure, List<ManagedProfile>>> call() {
    return repository.listProfiles();
  }
}
