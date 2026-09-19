import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/cerita_kelas/domain/entities/cerita_kelas.dart';
import 'package:beranibicara/features/cerita_kelas/domain/repositories/cerita_kelas_repository.dart';

class ListCeritaKelasUseCase {
  final CeritaKelasRepository repository;

  ListCeritaKelasUseCase(this.repository);

  Future<Either<Failure, List<CeritaKelas>>> call({
    int? kelasId,
    List<int>? kelasIds,
  }) =>
      repository.list(kelasId: kelasId, kelasIds: kelasIds);
}
