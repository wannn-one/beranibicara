import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/admin/domain/entities/admin_stats.dart';
import 'package:beranibicara/features/admin/domain/repositories/admin_repository.dart';

class GetAdminStatsUseCase {
  final AdminRepository repository;

  GetAdminStatsUseCase(this.repository);

  Future<Either<Failure, AdminStats>> call() => repository.getStats();
}
