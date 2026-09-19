import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/cerita_kelas/domain/repositories/cerita_kelas_repository.dart';

class DeleteTanggapanCeritaUseCase {
  final CeritaKelasRepository repository;

  DeleteTanggapanCeritaUseCase(this.repository);

  Future<Either<Failure, void>> call(int id) => repository.deleteComment(id);
}
