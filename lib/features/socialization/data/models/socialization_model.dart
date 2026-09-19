import 'package:beranibicara/features/socialization/domain/entities/socialization.dart';

class SocializationModel {
  final int id;
  final String? authorId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final String? authorName;
  final String? coverImageUrl;

  const SocializationModel({
    required this.id,
    this.authorId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.publishedAt,
    this.authorName,
    this.coverImageUrl,
  });

  factory SocializationModel.fromJson(Map<String, dynamic> json) {
    final profile = json['author'] ?? json['profiles'];
    return SocializationModel(
      id: json['id'] as int,
      authorId: json['author_id'] as String?,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      authorName: profile is Map ? profile['full_name'] as String? : json['author_name'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
    );
  }

  Socialization toEntity() {
    return Socialization(
      id: id,
      authorId: authorId,
      title: title,
      content: content,
      createdAt: createdAt,
      publishedAt: publishedAt,
      authorName: authorName,
      coverImageUrl: coverImageUrl,
    );
  }
}
