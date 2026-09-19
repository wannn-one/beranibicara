import 'package:equatable/equatable.dart';

class TanggapanCerita extends Equatable {
  final int id;
  final int ceritaId;
  final String authorId;
  final String tanggapan;
  final DateTime createdAt;
  final String? authorName;

  const TanggapanCerita({
    required this.id,
    required this.ceritaId,
    required this.authorId,
    required this.tanggapan,
    required this.createdAt,
    this.authorName,
  });

  @override
  List<Object?> get props =>
      [id, ceritaId, authorId, tanggapan, createdAt, authorName];
}
