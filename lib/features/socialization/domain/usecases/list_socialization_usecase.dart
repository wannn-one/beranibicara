import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/socialization/domain/entities/socialization.dart';
import 'package:beranibicara/features/socialization/domain/repositories/socialization_repository.dart';

class ListSocializationUseCase {
  final SocializationRepository repository;

  ListSocializationUseCase(this.repository);

  Future<Either<Failure, List<Socialization>>> call() =>
      repository.listPublished();
}
