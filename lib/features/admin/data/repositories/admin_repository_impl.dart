import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/exceptions.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/admin/domain/entities/managed_profile.dart';
import 'package:beranibicara/features/admin/domain/entities/managed_kelas.dart';
import 'package:beranibicara/features/admin/domain/entities/admin_stats.dart';
import 'package:beranibicara/features/admin/domain/repositories/admin_repository.dart';
import 'package:beranibicara/features/admin/data/datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<ManagedProfile>>> listProfiles() async {
    try {
      final models = await remoteDataSource.listProfiles();
      return Right(models.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal memuat pengguna: $e'));
    }
  }

  @override
  Future<Either<Failure, ManagedProfile>> updateRole({
    required String userId,
    required UserRole role,
  }) async {
    try {
      final model = await remoteDataSource.updateRole(
        userId: userId,
        role: role.value,
      );
      return Right(model.toEntity());
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal mengubah role: $e'));
    }
  }

  @override
  Future<Either<Failure, ManagedProfile>> updateStatus({
    required String userId,
    required UserStatus status,
    required String adminId,
    String? reason,
  }) async {
    try {
      final model = await remoteDataSource.updateStatus(
        userId: userId,
        status: status.value,
        adminId: adminId,
        reason: reason,
      );
      return Right(model.toEntity());
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal mengubah status: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ManagedKelas>>> listKelas() async {
    try {
      final models = await remoteDataSource.listKelas();
      return Right(models.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal memuat kelas: $e'));
    }
  }

  @override
  Future<Either<Failure, ManagedKelas>> createKelas({
    required int tingkat,
    required String jurusan,
  }) async {
    try {
      final model = await remoteDataSource.createKelas(
        tingkat: tingkat,
        jurusan: jurusan,
      );
      return Right(model.toEntity());
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal menambah kelas: $e'));
    }
  }

  @override
  Future<Either<Failure, ManagedKelas>> assignWaliKelas({
    required int kelasId,
    required String? waliKelasId,
  }) async {
    try {
      final model = await remoteDataSource.assignWaliKelas(
        kelasId: kelasId,
        waliKelasId: waliKelasId,
      );
      return Right(model.toEntity());
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal mengubah wali kelas: $e'));
    }
  }

  @override
  Future<Either<Failure, ManagedProfile>> updateStudentKelas({
    required String userId,
    required int? kelasId,
  }) async {
    try {
      final model = await remoteDataSource.updateStudentKelas(
        userId: userId,
        kelasId: kelasId,
      );
      return Right(model.toEntity());
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal mengubah kelas siswa: $e'));
    }
  }

  @override
  Future<Either<Failure, AdminStats>> getStats() async {
    try {
      final stats = await remoteDataSource.getStats();
      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal memuat statistik: $e'));
    }
  }
}
