import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/cerita_kelas/domain/entities/tanggapan_cerita.dart';
import 'package:beranibicara/features/cerita_kelas/domain/repositories/cerita_kelas_repository.dart';

class AddTanggapanCeritaUseCase {
  final CeritaKelasRepository repository;

  AddTanggapanCeritaUseCase(this.repository);

  Future<Either<Failure, TanggapanCerita>> call({
    required int ceritaId,
    required String authorId,
    required String tanggapan,
  }) {
    final text = tanggapan.trim();
    if (text.isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Tanggapan tidak boleh kosong')),
      );
    }
    if (text.length > AppConstants.maxTanggapanLength) {
      return Future.value(
        const Left(ValidationFailure(message: 'Tanggapan terlalu panjang')),
      );
    }
    return repository.addComment(
      ceritaId: ceritaId,
      authorId: authorId,
      tanggapan: text,
    );
  }
}
