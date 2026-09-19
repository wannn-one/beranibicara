import 'package:beranibicara/features/reports/domain/entities/report.dart';
import 'package:beranibicara/features/log_penanganan/domain/entities/log_penanganan.dart';

class LogPenangananModel {
  final int id;
  final int reportId;
  final String authorId;
  final String catatan;
  final String tahapan;
  final DateTime createdAt;
  final String? authorName;

  const LogPenangananModel({
    required this.id,
    required this.reportId,
    required this.authorId,
    required this.catatan,
    required this.tahapan,
    required this.createdAt,
    this.authorName,
  });

  factory LogPenangananModel.fromJson(Map<String, dynamic> json) {
    return LogPenangananModel(
      id: json['id'] as int,
      reportId: json['report_id'] as int,
      authorId: json['author_id'] as String,
      catatan: json['catatan'] as String,
      tahapan: json['tahapan'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: json['author_name'] as String?,
    );
  }

  LogPenanganan toEntity() {
    return LogPenanganan(
      id: id,
      reportId: reportId,
      authorId: authorId,
      catatan: catatan,
      tahapan: TahapanType.fromString(tahapan) ?? TahapanType.penerimaan,
      createdAt: createdAt,
      authorName: authorName,
    );
  }
}
