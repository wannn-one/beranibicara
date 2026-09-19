import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';

part 'report_model.freezed.dart';

@freezed
class ReportModel with _$ReportModel {
  const ReportModel._();

  const factory ReportModel({
    required String id,
    required String reporterId,
    String? title,
    required String description,
    required String status,
    required bool isAnonymous,
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
    String? reporterName,
  }) = _ReportModel;

  /// Create from Supabase JSON (snake_case)
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'].toString(),
      reporterId: json['reporter_id'] as String,
      title: json['title'] as String?,
      description: json['description'] as String,
      status: json['status'] as String,
      isAnonymous: json['is_anonymous'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      deletedBy: json['deleted_by'] as String?,
      reporterName: _reporterNameFromJson(json),
    );
  }

  /// Convert to Supabase JSON (snake_case)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'title': title,
      'description': description,
      'status': status,
      'is_anonymous': isAnonymous,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'deleted_by': deletedBy,
    };
  }

  static String? _reporterNameFromJson(Map<String, dynamic> json) {
    final reporter = json['reporter'];
    if (reporter is Map<String, dynamic>) {
      final name = reporter['full_name'] as String?;
      if (name != null && name.trim().isNotEmpty) return name.trim();
    }
    return null;
  }

  /// Convert Model to Entity
  Report toEntity() {
    return Report(
      id: id,
      reporterId: reporterId,
      title: title,
      description: description,
      status: ReportStatus.fromString(status),
      isAnonymous: isAnonymous,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      deletedBy: deletedBy,
      reporterName: reporterName,
    );
  }

  /// Convert Entity to Model
  static ReportModel fromEntity(Report report) {
    return ReportModel(
      id: report.id,
      reporterId: report.reporterId,
      title: report.title,
      description: report.description,
      status: report.status.value,
      isAnonymous: report.isAnonymous,
      createdAt: report.createdAt,
      updatedAt: report.updatedAt,
      deletedAt: report.deletedAt,
      deletedBy: report.deletedBy,
      reporterName: report.reporterName,
    );
  }
}
