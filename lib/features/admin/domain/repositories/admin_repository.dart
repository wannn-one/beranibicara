import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/admin/domain/entities/managed_profile.dart';
import 'package:beranibicara/features/admin/domain/entities/managed_kelas.dart';
import 'package:beranibicara/features/admin/domain/entities/admin_stats.dart';

abstract class AdminRepository {
  Future<Either<Failure, List<ManagedProfile>>> listProfiles();

  Future<Either<Failure, ManagedProfile>> updateRole({
    required String userId,
    required UserRole role,
  });

  Future<Either<Failure, ManagedProfile>> updateStatus({
    required String userId,
    required UserStatus status,
    required String adminId,
    String? reason,
  });

  Future<Either<Failure, ManagedProfile>> updateStudentKelas({
    required String userId,
    required int? kelasId,
  });

  Future<Either<Failure, List<ManagedKelas>>> listKelas();

  Future<Either<Failure, ManagedKelas>> createKelas({
    required int tingkat,
    required String jurusan,
  });

  Future<Either<Failure, ManagedKelas>> assignWaliKelas({
    required int kelasId,
    required String? waliKelasId,
  });

  Future<Either<Failure, AdminStats>> getStats();
}
