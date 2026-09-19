import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/exceptions.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';
import 'package:beranibicara/features/log_penanganan/domain/entities/log_penanganan.dart';
import 'package:beranibicara/features/log_penanganan/domain/repositories/log_penanganan_repository.dart';
import 'package:beranibicara/features/log_penanganan/data/datasources/log_penanganan_remote_datasource.dart';

class LogPenangananRepositoryImpl implements LogPenangananRepository {
  final LogPenangananRemoteDataSource remoteDataSource;

  LogPenangananRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<LogPenanganan>>> getByReportId(
    int reportId,
  ) async {
    try {
      final models = await remoteDataSource.getByReportId(reportId);
      return Right(models.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal memuat log penanganan: $e'));
    }
  }

  @override
  Future<Either<Failure, LogPenanganan>> create({
    required int reportId,
    required String authorId,
    required String catatan,
    required TahapanType tahapan,
  }) async {
    try {
      final model = await remoteDataSource.create(
        reportId: reportId,
        authorId: authorId,
        catatan: catatan,
        tahapan: tahapan.value,
      );
      return Right(model.toEntity());
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal menambah log: $e'));
    }
  }
}
