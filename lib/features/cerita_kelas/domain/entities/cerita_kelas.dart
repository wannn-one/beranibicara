import 'package:equatable/equatable.dart';

class CeritaKelas extends Equatable {
  final int id;
  final String authorId;
  final int kelasId;
  final String judul;
  final String konten;
  final String? gambarUrl;
  final bool isPublished;
  final DateTime createdAt;
  final String? authorName;

  const CeritaKelas({
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

  @override
  List<Object?> get props => [
        id,
        authorId,
        kelasId,
        judul,
        konten,
        gambarUrl,
        isPublished,
        createdAt,
        authorName,
      ];
}
