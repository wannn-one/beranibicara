import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:beranibicara/features/balasan/domain/entities/balasan_laporan.dart';
import 'package:beranibicara/features/balasan/domain/usecases/create_balasan_usecase.dart';
import 'package:beranibicara/features/balasan/domain/usecases/get_balasan_by_report_id_usecase.dart';
import 'package:beranibicara/features/balasan/domain/usecases/delete_balasan_usecase.dart';
import 'package:beranibicara/features/balasan/domain/usecases/watch_balasan_by_report_id_usecase.dart';

/// State for Balasan feature
enum BalasanStatus {
  initial,
  loading,
  loaded,
  sending,
  success,
  error,
}

/// Provider for managing Balasan Laporan state
/// 
/// Handles:
/// - Loading replies for a report
/// - Real-time updates via stream
/// - Sending new replies
/// - Deleting replies
class BalasanNotifier extends ChangeNotifier {
  final CreateBalasanUseCase createBalasanUseCase;
  final GetBalasanByReportIdUseCase getBalasanByReportIdUseCase;
  final DeleteBalasanUseCase deleteBalasanUseCase;
  final WatchBalasanByReportIdUseCase watchBalasanByReportIdUseCase;

  BalasanNotifier({
    required this.createBalasanUseCase,
    required this.getBalasanByReportIdUseCase,
    required this.deleteBalasanUseCase,
    required this.watchBalasanByReportIdUseCase,
  });

  // State
  BalasanStatus _status = BalasanStatus.initial;
  List<BalasanLaporan> _balasanList = [];
  String? _errorMessage;
  bool _isSending = false;
  StreamSubscription<List<BalasanLaporan>>? _balasanSubscription;

  // Getters
  BalasanStatus get status => _status;
  List<BalasanLaporan> get balasanList => _balasanList;
  String? get errorMessage => _errorMessage;
  bool get isSending => _isSending;
  bool get isEmpty => _balasanList.isEmpty;
  int get balasanCount => _balasanList.length;

  /// Load replies for a report (one-time fetch)
  Future<void> loadBalasan(int reportId) async {
    _status = BalasanStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await getBalasanByReportIdUseCase(reportId);

    result.fold(
      (failure) {
        _status = BalasanStatus.error;
        _errorMessage = failure.message;
        _balasanList = [];
      },
      (balasanList) {
        _status = BalasanStatus.loaded;
        _balasanList = balasanList;
        _errorMessage = null;
      },
    );

    notifyListeners();
  }

  /// Watch replies in real-time
  /// 
  /// Subscribes to stream and updates state automatically
  void watchBalasan(int reportId) {
    // Cancel previous subscription if exists
    _balasanSubscription?.cancel();

    _status = BalasanStatus.loading;
    _errorMessage = null;
    notifyListeners();

    _balasanSubscription = watchBalasanByReportIdUseCase(reportId).listen(
      (balasanList) {
        _status = BalasanStatus.loaded;
        _balasanList = balasanList;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _status = BalasanStatus.error;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Stop watching replies
  void stopWatching() {
    _balasanSubscription?.cancel();
    _balasanSubscription = null;
  }

  /// Create a new reply
  /// 
  /// Returns true on success, false on failure
  Future<bool> createBalasan({
    required int reportId,
    required String authorId,
    required String pesan,
  }) async {
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    final result = await createBalasanUseCase(
      reportId: reportId,
      authorId: authorId,
      pesan: pesan,
    );

    _isSending = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (balasan) {
        // If not using real-time, manually add to list
        if (_balasanSubscription == null) {
          _balasanList.add(balasan);
        }
        _errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Delete a reply
  /// 
  /// Returns true on success, false on failure
  Future<bool> deleteBalasan({
    required int balasanId,
    required String userId,
  }) async {
    _errorMessage = null;
    notifyListeners();

    final result = await deleteBalasanUseCase(
      balasanId: balasanId,
      userId: userId,
    );

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        // If not using real-time, manually remove from list
        if (_balasanSubscription == null) {
          _balasanList.removeWhere((b) => b.id == balasanId);
        }
        _errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset state
  void reset() {
    _status = BalasanStatus.initial;
    _balasanList = [];
    _errorMessage = null;
    _isSending = false;
    _balasanSubscription?.cancel();
    _balasanSubscription = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _balasanSubscription?.cancel();
    super.dispose();
  }
}
