import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/cerita_kelas/domain/entities/tanggapan_cerita.dart';
import 'package:beranibicara/features/cerita_kelas/domain/repositories/cerita_kelas_repository.dart';

class ListTanggapanCeritaUseCase {
  final CeritaKelasRepository repository;

  ListTanggapanCeritaUseCase(this.repository);

  Future<Either<Failure, List<TanggapanCerita>>> call(int ceritaId) =>
      repository.listComments(ceritaId);
}
