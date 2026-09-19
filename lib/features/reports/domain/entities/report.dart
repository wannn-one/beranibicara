import 'package:equatable/equatable.dart';

/// Report status enum - matches database enum
enum ReportStatus {
  baru('baru'),
  diproses('diproses'),
  selesai('selesai'),
  ditolak('ditolak'),
  spam('spam');

  const ReportStatus(this.value);
  final String value;

  static ReportStatus fromString(String value) {
    if (value == 'ditinjau' || value == 'ditindaklanjuti') {
      return ReportStatus.diproses;
    }
    return ReportStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ReportStatus.baru,
    );
  }
}

/// Tahapan enum - stages of report handling (matches database enum)
/// Used in log_penanganan table, NOT in reports table
enum TahapanType {
  penerimaan('penerimaan'),
  investigasi('investigasi'),
  mediasi('mediasi'),
  tindakan('tindakan'),
  monitoring('monitoring'),
  penutupan('penutupan');

  const TahapanType(this.value);
  final String value;

  static TahapanType? fromString(String? value) {
    if (value == null) return null;
    return TahapanType.values.firstWhere(
      (tahapan) => tahapan.value == value,
      orElse: () => TahapanType.penerimaan,
    );
  }

  String get label {
    switch (this) {
      case TahapanType.penerimaan:
        return 'Penerimaan';
      case TahapanType.investigasi:
        return 'Investigasi';
      case TahapanType.mediasi:
        return 'Mediasi';
      case TahapanType.tindakan:
        return 'Tindakan';
      case TahapanType.monitoring:
        return 'Monitoring';
      case TahapanType.penutupan:
        return 'Penutupan';
    }
  }
}

/// Report entity - represents a report in the domain layer
/// Matches database table: public.reports
class Report extends Equatable {
  final String id;
  final String reporterId;
  final String? title;
  final String description;
  final ReportStatus status;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;
  final String? reporterName;

  const Report({
    required this.id,
    required this.reporterId,
    this.title,
    required this.description,
    required this.status,
    required this.isAnonymous,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
    this.reporterName,
  });

  /// Check if report is editable (only when status is baru)
  bool get isEditable => status == ReportStatus.baru;

  /// Check if report is in progress
  bool get isInProgress => status == ReportStatus.diproses;

  /// Check if report is completed
  bool get isCompleted => status == ReportStatus.selesai;

  /// Check if report is rejected
  bool get isRejected =>
      status == ReportStatus.ditolak || status == ReportStatus.spam;

  /// Check if report is soft deleted
  bool get isDeleted => deletedAt != null;

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case ReportStatus.baru:
        return 'Baru';
      case ReportStatus.diproses:
        return 'Diproses';
      case ReportStatus.selesai:
        return 'Selesai';
      case ReportStatus.ditolak:
        return 'Ditolak';
      case ReportStatus.spam:
        return 'Spam';
    }
  }

  @override
  List<Object?> get props => [
        id,
        reporterId,
        title,
        description,
        status,
        isAnonymous,
        createdAt,
        updatedAt,
        deletedAt,
        deletedBy,
        reporterName,
      ];
}
