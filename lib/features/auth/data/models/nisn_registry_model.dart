import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:beranibicara/features/auth/domain/entities/nisn_registry.dart';

part 'nisn_registry_model.freezed.dart';

/// NISN Registry Data Model with Freezed
@freezed
class NisnRegistryModel with _$NisnRegistryModel {
  const NisnRegistryModel._(); // Private constructor for methods

  const factory NisnRegistryModel({
    required String nisn,
    required String namaSiswa,
    int? tingkat,
    String? jurusan,
    @Default(false) bool isRegistered,
    String? userId,
    required DateTime createdAt,
    DateTime? registeredAt,
  }) = _NisnRegistryModel;

  /// From JSON (from Supabase)
  factory NisnRegistryModel.fromJson(Map<String, dynamic> json) {
    return NisnRegistryModel(
      nisn: json['nisn'] as String,
      namaSiswa: json['nama_siswa'] as String,
      tingkat: (json['tingkat'] as num?)?.toInt(),
      jurusan: json['jurusan'] as String?,
      isRegistered: json['is_registered'] as bool? ?? false,
      userId: json['user_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      registeredAt: json['registered_at'] == null
          ? null
          : DateTime.parse(json['registered_at'] as String),
    );
  }

  /// Convert to domain entity
  NisnRegistry toEntity() {
    return NisnRegistry(
      nisn: nisn,
      namaSiswa: namaSiswa,
      tingkat: tingkat,
      jurusan: jurusan,
      isRegistered: isRegistered,
      userId: userId,
      createdAt: createdAt,
      registeredAt: registeredAt,
    );
  }

  /// Create from domain entity
  factory NisnRegistryModel.fromEntity(NisnRegistry registry) {
    return NisnRegistryModel(
      nisn: registry.nisn,
      namaSiswa: registry.namaSiswa,
      tingkat: registry.tingkat,
      jurusan: registry.jurusan,
      isRegistered: registry.isRegistered,
      userId: registry.userId,
      createdAt: registry.createdAt,
      registeredAt: registry.registeredAt,
    );
  }
}
