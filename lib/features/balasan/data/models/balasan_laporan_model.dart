import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:beranibicara/features/balasan/domain/entities/balasan_laporan.dart';

part 'balasan_laporan_model.freezed.dart';

/// Data model for Balasan Laporan with Freezed
/// 
/// Maps to/from Supabase JSON (snake_case) and domain entity
@freezed
class BalasanLaporanModel with _$BalasanLaporanModel {
  const BalasanLaporanModel._();

  const factory BalasanLaporanModel({
    required int id,
    required int reportId,
    required String authorId,
    required String pesan,
    required DateTime createdAt,
    String? authorName,
    String? authorRole,
  }) = _BalasanLaporanModel;

  /// Convert from Supabase JSON (snake_case) to model
  factory BalasanLaporanModel.fromJson(Map<String, dynamic> json) {
    return BalasanLaporanModel(
      id: json['id'] as int,
      reportId: json['report_id'] as int,
      authorId: json['author_id'] as String,
      pesan: json['pesan'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      // Optional author info from join
      authorName: json['author_name'] as String?,
      authorRole: json['author_role'] as String?,
    );
  }

  /// Convert model to Supabase JSON (snake_case)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'author_id': authorId,
      'pesan': pesan,
      'created_at': createdAt.toIso8601String(),
      if (authorName != null) 'author_name': authorName,
      if (authorRole != null) 'author_role': authorRole,
    };
  }

  /// Convert model to domain entity
  BalasanLaporan toEntity() {
    return BalasanLaporan(
      id: id,
      reportId: reportId,
      authorId: authorId,
      pesan: pesan,
      createdAt: createdAt,
      authorName: authorName,
      authorRole: authorRole,
    );
  }

  /// Create model from domain entity
  static BalasanLaporanModel fromEntity(BalasanLaporan entity) {
    return BalasanLaporanModel(
      id: entity.id,
      reportId: entity.reportId,
      authorId: entity.authorId,
      pesan: entity.pesan,
      createdAt: entity.createdAt,
      authorName: entity.authorName,
      authorRole: entity.authorRole,
    );
  }
}
