import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/exceptions.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/socialization/domain/entities/socialization.dart';
import 'package:beranibicara/features/socialization/domain/repositories/socialization_repository.dart';
import 'package:beranibicara/features/socialization/data/datasources/socialization_remote_datasource.dart';

class SocializationRepositoryImpl implements SocializationRepository {
  final SocializationRemoteDataSource remoteDataSource;

  SocializationRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Socialization>>> listPublished() async {
    try {
      final models = await remoteDataSource.listPublished();
      return Right(models.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal memuat sosialisasi: $e'));
    }
  }

  @override
  Future<Either<Failure, Socialization>> getById(int id) async {
    try {
      final model = await remoteDataSource.getById(id);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal memuat artikel: $e'));
    }
  }

  @override
  Future<Either<Failure, Socialization>> create({
    required String authorId,
    required String title,
    required String content,
    required String imagePath,
  }) async {
    try {
      final model = await remoteDataSource.create(
        authorId: authorId,
        title: title,
        content: content,
        imagePath: imagePath,
      );
      return Right(model.toEntity());
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on FileException catch (e) {
      return Left(FileFailure(message: e.message));
    } on FileSizeExceededException catch (e) {
      return Left(FileFailure(message: e.message));
    } on InvalidFileTypeException catch (e) {
      return Left(FileFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal membuat sosialisasi: $e'));
    }
  }

  @override
  Future<Either<Failure, Socialization>> update({
    required int id,
    required String title,
    required String content,
    String? imagePath,
  }) async {
    try {
      final model = await remoteDataSource.update(
        id: id,
        title: title,
        content: content,
        imagePath: imagePath,
      );
      return Right(model.toEntity());
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on FileException catch (e) {
      return Left(FileFailure(message: e.message));
    } on FileSizeExceededException catch (e) {
      return Left(FileFailure(message: e.message));
    } on InvalidFileTypeException catch (e) {
      return Left(FileFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal mengubah sosialisasi: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> delete(int id) async {
    try {
      await remoteDataSource.delete(id);
      return const Right(null);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal menghapus sosialisasi: $e'));
    }
  }
}
