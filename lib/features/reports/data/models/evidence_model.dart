import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:beranibicara/features/reports/domain/entities/evidence.dart';

part 'evidence_model.freezed.dart';

@freezed
class EvidenceModel with _$EvidenceModel {
  const EvidenceModel._();

  const factory EvidenceModel({
    required String id,
    required String reportId,
    required String fileUrl,
    required String fileType,
    required DateTime createdAt,
  }) = _EvidenceModel;

  /// Create from Supabase JSON (snake_case)
  factory EvidenceModel.fromJson(Map<String, dynamic> json) {
    return EvidenceModel(
      id: json['id'].toString(),
      reportId: json['report_id'].toString(),
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to Supabase JSON (snake_case)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'file_url': fileUrl,
      'file_type': fileType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert Model to Entity
  Evidence toEntity() {
    return Evidence(
      id: id,
      reportId: reportId,
      fileUrl: fileUrl,
      fileType: FileType.fromString(fileType),
      createdAt: createdAt,
    );
  }

  /// Convert Entity to Model
  static EvidenceModel fromEntity(Evidence evidence) {
    return EvidenceModel(
      id: evidence.id,
      reportId: evidence.reportId,
      fileUrl: evidence.fileUrl,
      fileType: evidence.fileType.value,
      createdAt: evidence.createdAt,
    );
  }
}
