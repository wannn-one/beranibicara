import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/socialization/domain/entities/socialization.dart';

abstract class SocializationRepository {
  Future<Either<Failure, List<Socialization>>> listPublished();

  Future<Either<Failure, Socialization>> getById(int id);

  Future<Either<Failure, Socialization>> create({
    required String authorId,
    required String title,
    required String content,
    required String imagePath,
  });

  Future<Either<Failure, Socialization>> update({
    required int id,
    required String title,
    required String content,
    String? imagePath,
  });

  Future<Either<Failure, void>> delete(int id);
}
