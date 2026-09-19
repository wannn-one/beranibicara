import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/cerita_kelas/domain/entities/cerita_kelas.dart';
import 'package:beranibicara/features/cerita_kelas/domain/repositories/cerita_kelas_repository.dart';

class CreateCeritaKelasUseCase {
  final CeritaKelasRepository repository;

  CreateCeritaKelasUseCase(this.repository);

  Future<Either<Failure, CeritaKelas>> call({
    required String authorId,
    required int kelasId,
    required String judul,
    required String konten,
    String? imagePath,
  }) {
    final title = judul.trim();
    final body = konten.trim();
    if (title.length < 3) {
      return Future.value(
        const Left(ValidationFailure(message: 'Judul minimal 3 karakter')),
      );
    }
    if (title.length > AppConstants.maxCeritaKelasJudulLength) {
      return Future.value(
        const Left(ValidationFailure(message: 'Judul terlalu panjang')),
      );
    }
    if (body.length < AppConstants.minCeritaKelasKontenLength) {
      return Future.value(
        const Left(ValidationFailure(message: 'Isi minimal 10 karakter')),
      );
    }
    return repository.create(
      authorId: authorId,
      kelasId: kelasId,
      judul: title,
      konten: body,
      imagePath: imagePath,
    );
  }
}
