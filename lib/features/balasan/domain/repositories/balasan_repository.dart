import 'package:dartz/dartz.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/balasan/domain/entities/balasan_laporan.dart';

/// Repository interface for Balasan Laporan operations
/// 
/// Defines the contract for managing report replies in the data layer.
abstract class BalasanRepository {
  /// Create a new reply to a report
  /// 
  /// [reportId] - ID of the report being replied to
  /// [authorId] - ID of the user creating the reply (TPPK only)
  /// [pesan] - Message content of the reply
  /// 
  /// Returns [Right(BalasanLaporan)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, BalasanLaporan>> createBalasan({
    required int reportId,
    required String authorId,
    required String pesan,
  });

  /// Get all replies for a specific report
  /// 
  /// [reportId] - ID of the report
  /// 
  /// Returns [Right(List<BalasanLaporan>)] on success, ordered by created_at ASC
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, List<BalasanLaporan>>> getBalasanByReportId(int reportId);

  /// Delete a reply (TPPK/Admin only)
  /// 
  /// [balasanId] - ID of the reply to delete
  /// [userId] - ID of the user attempting deletion (for authorization)
  /// 
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> deleteBalasan({
    required int balasanId,
    required String userId,
  });

  /// Stream of replies for real-time updates
  /// 
  /// [reportId] - ID of the report to listen to
  /// 
  /// Emits new list whenever a reply is added/deleted
  Stream<List<BalasanLaporan>> watchBalasanByReportId(int reportId);
}
