import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/cerita_kelas/domain/repositories/cerita_kelas_repository.dart';

class DeleteCeritaKelasUseCase {
  final CeritaKelasRepository repository;

  DeleteCeritaKelasUseCase(this.repository);

  Future<Either<Failure, void>> call(int id) => repository.delete(id);
}
