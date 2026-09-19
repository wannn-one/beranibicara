import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// User Data Model with Freezed
@freezed
class UserModel with _$UserModel {
  const UserModel._(); // Private constructor for methods

  const factory UserModel({
    required String id,
    required String email,
    String? fullName,
    @Default('siswa') String role,
    @Default('aktif') String status,
    int? kelasId,
    String? nisn,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _UserModel;

  /// From JSON (from Supabase)
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Convert to domain entity
  User toEntity() {
    return User(
      id: id,
      email: email,
      fullName: fullName,
      role: UserRole.fromString(role),
      status: UserStatus.fromString(status),
      kelasId: kelasId,
      nisn: nisn,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from domain entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      role: user.role.value,
      status: user.status.value,
      kelasId: user.kelasId,
      nisn: user.nisn,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }

  /// From Supabase Auth User + Profile data
  factory UserModel.fromSupabase({
    required Map<String, dynamic> authUser,
    required Map<String, dynamic> profile,
  }) {
    return UserModel(
      id: authUser['id'] as String,
      email: authUser['email'] as String,
      fullName: profile['full_name'] as String?,
      role: profile['role'] as String? ?? 'siswa',
      status: profile['status'] as String? ?? 'aktif',
      kelasId: profile['kelas_id'] as int?,
      nisn: profile['nisn'] as String?,
      createdAt: profile['created_at'] != null
          ? DateTime.parse(profile['created_at'] as String)
          : DateTime.now(),
      updatedAt: profile['updated_at'] != null
          ? DateTime.parse(profile['updated_at'] as String)
          : null,
    );
  }
}
