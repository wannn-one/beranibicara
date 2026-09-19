import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/exceptions.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/reports/data/datasources/report_remote_datasource.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';
import 'package:beranibicara/features/reports/domain/entities/evidence.dart';
import 'package:beranibicara/features/reports/domain/repositories/report_repository.dart';

/// Implementation of ReportRepository
/// Converts exceptions from data layer to failures for domain layer
class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource remoteDataSource;

  ReportRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, Report>> createReport({
    String? title,
    required String description,
    required bool isAnonymous,
    required String reporterId,
  }) async {
    try {
      final reportModel = await remoteDataSource.createReport(
        title: title,
        description: description,
        isAnonymous: isAnonymous,
        reporterId: reporterId,
      );
      return Right(reportModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Report>> getReportById(String reportId) async {
    try {
      final reportModel = await remoteDataSource.getReportById(reportId);
      return Right(reportModel.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Report>>> getReportsByReporter(
      String reporterId) async {
    try {
      final reportModels =
          await remoteDataSource.getReportsByReporter(reporterId);
      final reports = reportModels.map((model) => model.toEntity()).toList();
      return Right(reports);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Report>>> getAllReports({
    ReportStatus? status,
    int? limit,
    int? offset,
  }) async {
    try {
      final reportModels = await remoteDataSource.getAllReports(
        status: status,
        limit: limit,
        offset: offset,
      );
      final reports = reportModels.map((model) => model.toEntity()).toList();
      return Right(reports);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Report>> updateReportStatus({
    required String reportId,
    required ReportStatus newStatus,
  }) async {
    try {
      final reportModel = await remoteDataSource.updateReportStatus(
        reportId: reportId,
        newStatus: newStatus,
      );
      return Right(reportModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Report>> updateReport({
    required String reportId,
    String? title,
    String? description,
    bool? isAnonymous,
  }) async {
    try {
      final reportModel = await remoteDataSource.updateReport(
        reportId: reportId,
        title: title,
        description: description,
        isAnonymous: isAnonymous,
      );
      return Right(reportModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReport({
    required String reportId,
    required String deletedBy,
  }) async {
    try {
      await remoteDataSource.deleteReport(
        reportId: reportId,
        deletedBy: deletedBy,
      );
      return const Right(null);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  // === Evidence Management ===

  @override
  Future<Either<Failure, List<Evidence>>> uploadEvidenceFiles({
    required String reportId,
    required List<String> filePaths,
  }) async {
    try {
      final evidenceModels = await remoteDataSource.uploadEvidenceFiles(
        reportId: reportId,
        filePaths: filePaths,
      );
      final evidence =
          evidenceModels.map((model) => model.toEntity()).toList();
      return Right(evidence);
    } on FileSizeExceededException catch (e) {
      return Left(FileFailure(message: e.message));
    } on InvalidFileTypeException catch (e) {
      return Left(FileFailure(message: e.message));
    } on FileUploadException catch (e) {
      return Left(FileFailure(message: e.message));
    } on FileException catch (e) {
      return Left(FileFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(FileFailure(message: 'Failed to upload files: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Evidence>>> getEvidenceByReportId(
      String reportId) async {
    try {
      final evidenceModels =
          await remoteDataSource.getEvidenceByReportId(reportId);
      final evidence =
          evidenceModels.map((model) => model.toEntity()).toList();
      return Right(evidence);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEvidence(String evidenceId) async {
    try {
      await remoteDataSource.deleteEvidence(evidenceId);
      return const Right(null);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on FileException catch (e) {
      return Left(FileFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(FileFailure(message: 'Failed to delete evidence: $e'));
    }
  }
}
