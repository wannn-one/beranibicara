import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';
import 'package:beranibicara/features/log_penanganan/domain/entities/log_penanganan.dart';

abstract class LogPenangananRepository {
  Future<Either<Failure, List<LogPenanganan>>> getByReportId(int reportId);

  Future<Either<Failure, LogPenanganan>> create({
    required int reportId,
    required String authorId,
    required String catatan,
    required TahapanType tahapan,
  });
}
