import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:beranibicara/features/auth/domain/entities/nisn_registry.dart';

part 'nisn_registry_model.freezed.dart';
part 'nisn_registry_model.g.dart';

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
  factory NisnRegistryModel.fromJson(Map<String, dynamic> json) =>
      _$NisnRegistryModelFromJson(json);

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
