import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/admin/domain/entities/managed_kelas.dart';
import 'package:beranibicara/features/admin/domain/repositories/admin_repository.dart';

class AssignWaliKelasUseCase {
  final AdminRepository repository;

  AssignWaliKelasUseCase(this.repository);

  Future<Either<Failure, ManagedKelas>> call({
    required int kelasId,
    required String? waliKelasId,
  }) {
    return repository.assignWaliKelas(
      kelasId: kelasId,
      waliKelasId: waliKelasId,
    );
  }
}
