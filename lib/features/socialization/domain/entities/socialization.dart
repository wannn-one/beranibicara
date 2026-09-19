import 'package:equatable/equatable.dart';

class Socialization extends Equatable {
  final int id;
  final String? authorId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final String? authorName;
  final String? coverImageUrl;

  const Socialization({
    required this.id,
    this.authorId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.publishedAt,
    this.authorName,
    this.coverImageUrl,
  });

  @override
  List<Object?> get props => [
        id,
        authorId,
        title,
        content,
        createdAt,
        publishedAt,
        authorName,
        coverImageUrl,
      ];
}
