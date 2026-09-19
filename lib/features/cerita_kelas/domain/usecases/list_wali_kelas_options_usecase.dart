import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/cerita_kelas/domain/entities/wali_kelas_option.dart';
import 'package:beranibicara/features/cerita_kelas/domain/repositories/cerita_kelas_repository.dart';

class ListWaliKelasOptionsUseCase {
  final CeritaKelasRepository repository;

  ListWaliKelasOptionsUseCase(this.repository);

  Future<Either<Failure, List<WaliKelasOption>>> call(String userId) =>
      repository.listWaliKelas(userId);
}
