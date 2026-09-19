import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/admin/domain/entities/managed_kelas.dart';
import 'package:beranibicara/features/admin/domain/repositories/admin_repository.dart';

class ListKelasUseCase {
  final AdminRepository repository;

  ListKelasUseCase(this.repository);

  Future<Either<Failure, List<ManagedKelas>>> call() => repository.listKelas();
}
