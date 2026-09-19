import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/cerita_kelas/domain/entities/cerita_kelas.dart';
import 'package:beranibicara/features/cerita_kelas/domain/repositories/cerita_kelas_repository.dart';

class GetCeritaKelasByIdUseCase {
  final CeritaKelasRepository repository;

  GetCeritaKelasByIdUseCase(this.repository);

  Future<Either<Failure, CeritaKelas>> call(int id) => repository.getById(id);
}
