import 'package:beranibicara/features/balasan/domain/entities/balasan_laporan.dart';
import 'package:beranibicara/features/balasan/domain/repositories/balasan_repository.dart';

/// Use Case: Watch replies in real-time
/// 
/// Business rules:
/// - Automatically updates when new replies are added
/// - Maintains chronological order (oldest first)
/// - Only shows replies for authorized users
class WatchBalasanByReportIdUseCase {
  final BalasanRepository repository;

  WatchBalasanByReportIdUseCase(this.repository);

  Stream<List<BalasanLaporan>> call(int reportId) {
    return repository.watchBalasanByReportId(reportId);
  }
}
