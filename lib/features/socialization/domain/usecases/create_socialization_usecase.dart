import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/socialization/domain/entities/socialization.dart';
import 'package:beranibicara/features/socialization/domain/repositories/socialization_repository.dart';

class CreateSocializationUseCase {
  final SocializationRepository repository;

  CreateSocializationUseCase(this.repository);

  Future<Either<Failure, Socialization>> call({
    required String authorId,
    required String title,
    required String content,
    required String imagePath,
  }) {
    if (title.trim().length < 3) {
      return Future.value(
        const Left(ValidationFailure(message: 'Judul minimal 3 karakter')),
      );
    }
    if (content.trim().length < 10) {
      return Future.value(
        const Left(ValidationFailure(message: 'Isi minimal 10 karakter')),
      );
    }
    if (imagePath.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Gambar wajib diunggah')),
      );
    }
    return repository.create(
      authorId: authorId,
      title: title.trim(),
      content: content.trim(),
      imagePath: imagePath,
    );
  }
}
