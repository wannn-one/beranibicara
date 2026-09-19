import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/auth/domain/repositories/auth_repository.dart';

/// Completes a student profile by assigning kelas. Non-students are rejected.
class CompleteStudentProfileUseCase {
  final AuthRepository repository;

  CompleteStudentProfileUseCase(this.repository);

  Future<Either<Failure, User>> call({
    required User user,
    required int kelasId,
  }) async {
    if (!user.isSiswa) {
      return const Left(
        ValidationFailure(
          message: 'Hanya siswa yang perlu memilih kelas',
        ),
      );
    }

    if (kelasId <= 0) {
      return const Left(
        ValidationFailure(message: 'Pilih kelas yang valid'),
      );
    }

    return repository.updateProfile(
      userId: user.id,
      kelasId: kelasId,
    );
  }
}
