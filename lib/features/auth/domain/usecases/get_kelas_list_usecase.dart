import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/auth/domain/entities/kelas.dart';
import 'package:beranibicara/features/auth/domain/repositories/auth_repository.dart';

class GetKelasListUseCase {
  final AuthRepository repository;

  GetKelasListUseCase(this.repository);

  Future<Either<Failure, List<Kelas>>> call() {
    return repository.getKelasList();
  }
}
