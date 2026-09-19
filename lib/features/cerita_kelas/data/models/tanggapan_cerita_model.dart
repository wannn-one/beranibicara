import 'package:beranibicara/features/cerita_kelas/domain/entities/tanggapan_cerita.dart';

class TanggapanCeritaModel {
  final int id;
  final int ceritaId;
  final String authorId;
  final String tanggapan;
  final DateTime createdAt;
  final String? authorName;

  const TanggapanCeritaModel({
    required this.id,
    required this.ceritaId,
    required this.authorId,
    required this.tanggapan,
    required this.createdAt,
    this.authorName,
  });

  factory TanggapanCeritaModel.fromJson(Map<String, dynamic> json) {
    final profile = json['author'] ?? json['profiles'];
    return TanggapanCeritaModel(
      id: json['id'] as int,
      ceritaId: json['cerita_id'] as int,
      authorId: json['author_id'] as String,
      tanggapan: json['tanggapan'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: profile is Map
          ? profile['full_name'] as String?
          : json['author_name'] as String?,
    );
  }

  TanggapanCerita toEntity() => TanggapanCerita(
        id: id,
        ceritaId: ceritaId,
        authorId: authorId,
        tanggapan: tanggapan,
        createdAt: createdAt,
        authorName: authorName,
      );
}
