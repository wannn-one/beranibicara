import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/admin/domain/entities/managed_kelas.dart';
import 'package:beranibicara/features/admin/domain/repositories/admin_repository.dart';

class CreateKelasUseCase {
  final AdminRepository repository;

  CreateKelasUseCase(this.repository);

  Future<Either<Failure, ManagedKelas>> call({
    required int tingkat,
    required String jurusan,
  }) {
    if (tingkat < 1 || tingkat > 6) {
      return Future.value(
        const Left(ValidationFailure(message: 'Tingkat harus 1–6')),
      );
    }
    if (jurusan.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Nama kelas tidak boleh kosong')),
      );
    }
    return repository.createKelas(tingkat: tingkat, jurusan: jurusan.trim());
  }
}
