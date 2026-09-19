import 'package:flutter/foundation.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';
import 'package:beranibicara/features/log_penanganan/domain/entities/log_penanganan.dart';
import 'package:beranibicara/features/log_penanganan/domain/usecases/get_log_penanganan_usecase.dart';
import 'package:beranibicara/features/log_penanganan/domain/usecases/create_log_penanganan_usecase.dart';

class LogPenangananNotifier extends ChangeNotifier {
  final GetLogPenangananUseCase getLogPenangananUseCase;
  final CreateLogPenangananUseCase createLogPenangananUseCase;

  LogPenangananNotifier({
    required this.getLogPenangananUseCase,
    required this.createLogPenangananUseCase,
  });

  List<LogPenanganan> _logs = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<LogPenanganan> get logs => _logs;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> load(int reportId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await getLogPenangananUseCase(reportId);
    _isLoading = false;

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _logs = [];
      },
      (logs) {
        _logs = logs;
        _errorMessage = null;
      },
    );
    notifyListeners();
  }

  Future<bool> addLog({
    required int reportId,
    required String authorId,
    required String catatan,
    required TahapanType tahapan,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await createLogPenangananUseCase(
      reportId: reportId,
      authorId: authorId,
      catatan: catatan,
      tahapan: tahapan,
    );

    _isSaving = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (log) {
        _logs = [..._logs, log];
        notifyListeners();
        return true;
      },
    );
  }

  void reset() {
    _logs = [];
    _isLoading = false;
    _isSaving = false;
    _errorMessage = null;
    notifyListeners();
  }
}
