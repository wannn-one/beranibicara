import 'package:flutter/material.dart';
import 'package:beranibicara/core/errors/failures.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart' as domain;
import 'package:beranibicara/features/reports/domain/entities/evidence.dart';
import 'package:beranibicara/features/reports/domain/usecases/create_report_usecase.dart';
import 'package:beranibicara/features/reports/domain/usecases/get_report_by_id_usecase.dart';
import 'package:beranibicara/features/reports/domain/usecases/get_reports_by_reporter_usecase.dart';
import 'package:beranibicara/features/reports/domain/usecases/get_all_reports_usecase.dart';
import 'package:beranibicara/features/reports/domain/usecases/update_report_status_usecase.dart';
import 'package:beranibicara/features/reports/domain/usecases/update_report_usecase.dart';
import 'package:beranibicara/features/reports/domain/usecases/delete_report_usecase.dart';
import 'package:beranibicara/features/reports/domain/usecases/upload_evidence_usecase.dart';
import 'package:beranibicara/features/reports/domain/usecases/get_evidence_by_report_id_usecase.dart';
import 'package:beranibicara/features/reports/domain/usecases/delete_evidence_usecase.dart';

/// Report notifier state enum
enum ReportNotifierStatus { initial, loading, loaded, error }

/// Report Notifier - manages report and evidence state
class ReportNotifier extends ChangeNotifier {
  // Use cases
  final CreateReportUseCase createReportUseCase;
  final GetReportByIdUseCase getReportByIdUseCase;
  final GetReportsByReporterUseCase getReportsByReporterUseCase;
  final GetAllReportsUseCase getAllReportsUseCase;
  final UpdateReportStatusUseCase updateReportStatusUseCase;
  final UpdateReportUseCase updateReportUseCase;
  final DeleteReportUseCase deleteReportUseCase;
  final UploadEvidenceUseCase uploadEvidenceUseCase;
  final GetEvidenceByReportIdUseCase getEvidenceByReportIdUseCase;
  final DeleteEvidenceUseCase deleteEvidenceUseCase;

  // State
  ReportNotifierStatus _status = ReportNotifierStatus.initial;
  List<domain.Report> _reports = [];
  domain.Report? _currentReport;
  List<Evidence> _currentReportEvidence = [];
  String? _errorMessage;
  bool _isCreating = false;
  bool _isUpdating = false;
  bool _isUploadingEvidence = false;

  // Getters
  ReportNotifierStatus get status => _status;
  List<domain.Report> get reports => _reports;
  domain.Report? get currentReport => _currentReport;
  List<Evidence> get currentReportEvidence => _currentReportEvidence;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ReportNotifierStatus.loading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get isUploadingEvidence => _isUploadingEvidence;

  ReportNotifier({
    required this.createReportUseCase,
    required this.getReportByIdUseCase,
    required this.getReportsByReporterUseCase,
    required this.getAllReportsUseCase,
    required this.updateReportStatusUseCase,
    required this.updateReportUseCase,
    required this.deleteReportUseCase,
    required this.uploadEvidenceUseCase,
    required this.getEvidenceByReportIdUseCase,
    required this.deleteEvidenceUseCase,
  });

  /// Create a new report
  Future<bool> createReport({
    String? title,
    required String description,
    required bool isAnonymous,
    required String reporterId,
  }) async {
    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    final result = await createReportUseCase(
      title: title,
      description: description,
      isAnonymous: isAnonymous,
      reporterId: reporterId,
    );

    _isCreating = false;

    return result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
        notifyListeners();
        return false;
      },
      (report) {
        // Add the new report to the list
        _reports.insert(0, report);
        _currentReport = report;
        notifyListeners();
        return true;
      },
    );
  }

  /// Get report by ID
  Future<void> getReportById(String reportId) async {
    _status = ReportNotifierStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await getReportByIdUseCase(reportId);

    await result.fold(
      (failure) async {
        _status = ReportNotifierStatus.error;
        _errorMessage = _mapFailureToMessage(failure);
        _currentReport = null;
        _currentReportEvidence = [];
      },
      (report) async {
        _status = ReportNotifierStatus.loaded;
        _currentReport = report;
        await _loadEvidence(reportId);
      },
    );

    notifyListeners();
  }

  Future<void> _loadEvidence(String reportId) async {
    final evidenceResult = await getEvidenceByReportIdUseCase(reportId);
    evidenceResult.fold(
      (_) {
        _currentReportEvidence = [];
      },
      (evidence) {
        _currentReportEvidence = evidence;
      },
    );
  }

  /// Upload evidence files for a report
  Future<bool> uploadEvidence({
    required String reportId,
    required List<String> filePaths,
  }) async {
    if (filePaths.isEmpty) return true;

    _isUploadingEvidence = true;
    _errorMessage = null;
    notifyListeners();

    final result = await uploadEvidenceUseCase(
      reportId: reportId,
      filePaths: filePaths,
    );

    _isUploadingEvidence = false;

    return result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
        notifyListeners();
        return false;
      },
      (evidence) {
        _currentReportEvidence = [..._currentReportEvidence, ...evidence];
        notifyListeners();
        return true;
      },
    );
  }

  /// Remove a single attachment
  Future<bool> deleteAttachment(String evidenceId) async {
    _errorMessage = null;
    notifyListeners();

    final result = await deleteEvidenceUseCase(evidenceId);

    return result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
        notifyListeners();
        return false;
      },
      (_) {
        _currentReportEvidence =
            _currentReportEvidence.where((e) => e.id != evidenceId).toList();
        notifyListeners();
        return true;
      },
    );
  }

  /// Get reports by reporter (for students)
  Future<void> getReportsByReporter(String reporterId) async {
    _status = ReportNotifierStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await getReportsByReporterUseCase(reporterId);

    result.fold(
      (failure) {
        _status = ReportNotifierStatus.error;
        _errorMessage = _mapFailureToMessage(failure);
        _reports = [];
      },
      (reports) {
        _status = ReportNotifierStatus.loaded;
        _reports = reports;
      },
    );

    notifyListeners();
  }

  /// Get all reports (for TPPK/Admin)
  Future<void> getAllReports({
    domain.ReportStatus? statusFilter,
    int? limit,
    int? offset,
  }) async {
    _status = ReportNotifierStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await getAllReportsUseCase(
      status: statusFilter,
      limit: limit,
      offset: offset,
    );

    result.fold(
      (failure) {
        _status = ReportNotifierStatus.error;
        _errorMessage = _mapFailureToMessage(failure);
        _reports = [];
      },
      (reports) {
        _status = ReportNotifierStatus.loaded;
        _reports = reports;
      },
    );

    notifyListeners();
  }

  /// Update report status (TPPK only)
  Future<bool> updateReportStatus({
    required String reportId,
    required domain.ReportStatus newStatus,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    final result = await updateReportStatusUseCase(
      reportId: reportId,
      newStatus: newStatus,
    );

    _isUpdating = false;

    return result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
        notifyListeners();
        return false;
      },
      (updatedReport) {
        // Update in list
        final index = _reports.indexWhere((r) => r.id == reportId);
        if (index != -1) {
          _reports[index] = updatedReport;
        }

        // Update current report if it matches
        if (_currentReport?.id == reportId) {
          _currentReport = updatedReport;
        }

        notifyListeners();
        return true;
      },
    );
  }

  /// Update report (student can edit)
  Future<bool> updateReport({
    required String reportId,
    String? title,
    String? description,
    bool? isAnonymous,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    final result = await updateReportUseCase(
      reportId: reportId,
      title: title,
      description: description,
      isAnonymous: isAnonymous,
    );

    _isUpdating = false;

    return result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
        notifyListeners();
        return false;
      },
      (updatedReport) {
        // Update in list
        final index = _reports.indexWhere((r) => r.id == reportId);
        if (index != -1) {
          _reports[index] = updatedReport;
        }

        // Update current report if it matches
        if (_currentReport?.id == reportId) {
          _currentReport = updatedReport;
        }

        notifyListeners();
        return true;
      },
    );
  }

  /// Delete report (soft delete)
  Future<bool> deleteReport({
    required String reportId,
    required String deletedBy,
  }) async {
    _errorMessage = null;
    notifyListeners();

    final result = await deleteReportUseCase(
      reportId: reportId,
      deletedBy: deletedBy,
    );

    return result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
        notifyListeners();
        return false;
      },
      (_) {
        // Remove from list
        _reports.removeWhere((r) => r.id == reportId);

        // Clear current report if it was deleted
        if (_currentReport?.id == reportId) {
          _currentReport = null;
        }

        notifyListeners();
        return true;
      },
    );
  }

  /// Clear current report
  void clearCurrentReport() {
    _currentReport = null;
    _currentReportEvidence = [];
    notifyListeners();
  }

  /// Clear all reports
  void clearReports() {
    _reports = [];
    _currentReport = null;
    _currentReportEvidence = [];
    _status = ReportNotifierStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  /// Map failure to user-friendly message
  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'Tidak ada koneksi internet. Silakan cek koneksi Anda.';
    } else if (failure is ValidationFailure) {
      return failure.message;
    } else if (failure is NotFoundFailure) {
      return 'Laporan tidak ditemukan.';
    } else if (failure is PermissionFailure) {
      return failure.message;
    } else if (failure is FileFailure) {
      return failure.message;
    } else {
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }
}
