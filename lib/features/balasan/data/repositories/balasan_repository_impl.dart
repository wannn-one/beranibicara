import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/exceptions.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/balasan/data/datasources/balasan_remote_datasource.dart';
import 'package:beranibicara/features/balasan/domain/entities/balasan_laporan.dart';
import 'package:beranibicara/features/balasan/domain/repositories/balasan_repository.dart';

/// Implementation of BalasanRepository
/// 
/// Bridges the data layer (DataSource) with the domain layer
/// Converts exceptions to failures following Clean Architecture
class BalasanRepositoryImpl implements BalasanRepository {
  final BalasanRemoteDataSource remoteDataSource;

  BalasanRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, BalasanLaporan>> createBalasan({
    required int reportId,
    required String authorId,
    required String pesan,
  }) async {
    try {
      final balasanModel = await remoteDataSource.createBalasan(
        reportId: reportId,
        authorId: authorId,
        pesan: pesan,
      );

      return Right(balasanModel.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on TimeoutException catch (e) {
      return Left(TimeoutFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal membuat balasan: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BalasanLaporan>>> getBalasanByReportId(
    int reportId,
  ) async {
    try {
      final balasanModels = await remoteDataSource.getBalasanByReportId(reportId);
      final balasanList = balasanModels.map((model) => model.toEntity()).toList();

      return Right(balasanList);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on TimeoutException catch (e) {
      return Left(TimeoutFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal mengambil balasan: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBalasan({
    required int balasanId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.deleteBalasan(
        balasanId: balasanId,
        userId: userId,
      );

      return const Right(null);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on TimeoutException catch (e) {
      return Left(TimeoutFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal menghapus balasan: $e'));
    }
  }

  @override
  Stream<List<BalasanLaporan>> watchBalasanByReportId(int reportId) {
    try {
      return remoteDataSource
          .watchBalasanByReportId(reportId)
          .map((models) => models.map((model) => model.toEntity()).toList());
    } catch (e) {
      // Return empty stream on error
      return Stream.error(UnknownFailure('Gagal memantau balasan: $e'));
    }
  }
}
