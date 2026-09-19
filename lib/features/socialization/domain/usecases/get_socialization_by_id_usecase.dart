import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/socialization/domain/entities/socialization.dart';
import 'package:beranibicara/features/socialization/domain/repositories/socialization_repository.dart';

class GetSocializationByIdUseCase {
  final SocializationRepository repository;

  GetSocializationByIdUseCase(this.repository);

  Future<Either<Failure, Socialization>> call(int id) => repository.getById(id);
}
