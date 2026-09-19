import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/socialization/domain/repositories/socialization_repository.dart';

class DeleteSocializationUseCase {
  final SocializationRepository repository;

  DeleteSocializationUseCase(this.repository);

  Future<Either<Failure, void>> call(int id) => repository.delete(id);
}
