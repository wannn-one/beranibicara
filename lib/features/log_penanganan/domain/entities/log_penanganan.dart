import 'package:equatable/equatable.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';

class LogPenanganan extends Equatable {
  final int id;
  final int reportId;
  final String authorId;
  final String catatan;
  final TahapanType tahapan;
  final DateTime createdAt;
  final String? authorName;

  const LogPenanganan({
    required this.id,
    required this.reportId,
    required this.authorId,
    required this.catatan,
    required this.tahapan,
    required this.createdAt,
    this.authorName,
  });

  @override
  List<Object?> get props => [
        id,
        reportId,
        authorId,
        catatan,
        tahapan,
        createdAt,
        authorName,
      ];
}
