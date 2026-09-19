import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/cerita_kelas/domain/entities/cerita_kelas.dart';
import 'package:beranibicara/features/cerita_kelas/domain/entities/tanggapan_cerita.dart';
import 'package:beranibicara/features/cerita_kelas/domain/entities/wali_kelas_option.dart';

abstract class CeritaKelasRepository {
  Future<Either<Failure, List<CeritaKelas>>> list({
    int? kelasId,
    List<int>? kelasIds,
  });

  Future<Either<Failure, CeritaKelas>> getById(int id);

  Future<Either<Failure, CeritaKelas>> create({
    required String authorId,
    required int kelasId,
    required String judul,
    required String konten,
    String? imagePath,
  });

  Future<Either<Failure, CeritaKelas>> update({
    required int id,
    required String judul,
    required String konten,
    String? imagePath,
  });

  Future<Either<Failure, void>> delete(int id);

  Future<Either<Failure, List<TanggapanCerita>>> listComments(int ceritaId);

  Future<Either<Failure, TanggapanCerita>> addComment({
    required int ceritaId,
    required String authorId,
    required String tanggapan,
  });

  Future<Either<Failure, void>> deleteComment(int id);

  Future<Either<Failure, List<WaliKelasOption>>> listWaliKelas(String userId);
}
