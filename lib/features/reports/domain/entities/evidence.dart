import 'package:equatable/equatable.dart';

/// File type enum - matches database file_type enum
enum FileType {
  image('image'),
  video('video'),
  audio('audio'),
  document('document');

  const FileType(this.value);
  final String value;

  static FileType fromString(String value) {
    return FileType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => FileType.image,
    );
  }
}

/// Evidence entity - represents evidence files for a report
/// Matches database table: public.evidence
class Evidence extends Equatable {
  final String id;
  final String reportId;
  final String fileUrl;
  final FileType fileType;
  final DateTime createdAt;

  const Evidence({
    required this.id,
    required this.reportId,
    required this.fileUrl,
    required this.fileType,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        reportId,
        fileUrl,
        fileType,
        createdAt,
      ];
}
