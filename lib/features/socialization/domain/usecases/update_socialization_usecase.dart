import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/socialization/domain/entities/socialization.dart';
import 'package:beranibicara/features/socialization/domain/repositories/socialization_repository.dart';

class UpdateSocializationUseCase {
  final SocializationRepository repository;

  UpdateSocializationUseCase(this.repository);

  Future<Either<Failure, Socialization>> call({
    required int id,
    required String title,
    required String content,
    String? imagePath,
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
    return repository.update(
      id: id,
      title: title.trim(),
      content: content.trim(),
      imagePath: imagePath,
    );
  }
}
