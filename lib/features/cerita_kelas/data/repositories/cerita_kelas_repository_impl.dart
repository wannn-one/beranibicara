import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/exceptions.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/cerita_kelas/data/datasources/cerita_kelas_remote_datasource.dart';
import 'package:beranibicara/features/cerita_kelas/domain/entities/cerita_kelas.dart';
import 'package:beranibicara/features/cerita_kelas/domain/entities/tanggapan_cerita.dart';
import 'package:beranibicara/features/cerita_kelas/domain/entities/wali_kelas_option.dart';
import 'package:beranibicara/features/cerita_kelas/domain/repositories/cerita_kelas_repository.dart';

class CeritaKelasRepositoryImpl implements CeritaKelasRepository {
  final CeritaKelasRemoteDataSource remoteDataSource;

  CeritaKelasRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<CeritaKelas>>> list({
    int? kelasId,
    List<int>? kelasIds,
  }) async {
    try {
      final models =
          await remoteDataSource.list(kelasId: kelasId, kelasIds: kelasIds);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal memuat cerita: $e'));
    }
  }

  @override
  Future<Either<Failure, CeritaKelas>> getById(int id) async {
    try {
      final model = await remoteDataSource.getById(id);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal memuat cerita: $e'));
    }
  }

  @override
  Future<Either<Failure, CeritaKelas>> create({
    required String authorId,
    required int kelasId,
    required String judul,
    required String konten,
    String? imagePath,
  }) async {
    try {
      final model = await remoteDataSource.create(
        authorId: authorId,
        kelasId: kelasId,
        judul: judul,
        konten: konten,
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
      return Left(UnknownFailure('Gagal membuat cerita: $e'));
    }
  }

  @override
  Future<Either<Failure, CeritaKelas>> update({
    required int id,
    required String judul,
    required String konten,
    String? imagePath,
  }) async {
    try {
      final model = await remoteDataSource.update(
        id: id,
        judul: judul,
        konten: konten,
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
      return Left(UnknownFailure('Gagal mengubah cerita: $e'));
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
      return Left(UnknownFailure('Gagal menghapus cerita: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TanggapanCerita>>> listComments(int ceritaId) async {
    try {
      final models = await remoteDataSource.listComments(ceritaId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal memuat tanggapan: $e'));
    }
  }

  @override
  Future<Either<Failure, TanggapanCerita>> addComment({
    required int ceritaId,
    required String authorId,
    required String tanggapan,
  }) async {
    try {
      final model = await remoteDataSource.addComment(
        ceritaId: ceritaId,
        authorId: authorId,
        tanggapan: tanggapan,
      );
      return Right(model.toEntity());
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal menambah tanggapan: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteComment(int id) async {
    try {
      await remoteDataSource.deleteComment(id);
      return const Right(null);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal menghapus tanggapan: $e'));
    }
  }

  @override
  Future<Either<Failure, List<WaliKelasOption>>> listWaliKelas(String userId) async {
    try {
      final items = await remoteDataSource.listWaliKelas(userId);
      return Right(items);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure('Gagal memuat kelas: $e'));
    }
  }
}
