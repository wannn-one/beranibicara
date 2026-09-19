import 'package:beranibicara/features/cerita_kelas/domain/entities/cerita_kelas.dart';

class CeritaKelasModel {
  final int id;
  final String authorId;
  final int kelasId;
  final String judul;
  final String konten;
  final String? gambarUrl;
  final bool isPublished;
  final DateTime createdAt;
  final String? authorName;

  const CeritaKelasModel({
    required this.id,
    required this.authorId,
    required this.kelasId,
    required this.judul,
    required this.konten,
    this.gambarUrl,
    required this.isPublished,
    required this.createdAt,
    this.authorName,
  });

  factory CeritaKelasModel.fromJson(Map<String, dynamic> json) {
    final profile = json['author'] ?? json['profiles'];
    return CeritaKelasModel(
      id: json['id'] as int,
      authorId: json['author_id'] as String,
      kelasId: json['kelas_id'] as int,
      judul: json['judul'] as String,
      konten: json['konten'] as String,
      gambarUrl: json['gambar_url'] as String?,
      isPublished: json['is_published'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: profile is Map
          ? profile['full_name'] as String?
          : json['author_name'] as String?,
    );
  }

  CeritaKelas toEntity() => CeritaKelas(
        id: id,
        authorId: authorId,
        kelasId: kelasId,
        judul: judul,
        konten: konten,
        gambarUrl: gambarUrl,
        isPublished: isPublished,
        createdAt: createdAt,
        authorName: authorName,
      );
}
