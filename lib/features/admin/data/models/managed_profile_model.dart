import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/admin/domain/entities/managed_profile.dart';

class ManagedProfileModel {
  final String id;
  final String? fullName;
  final String role;
  final String status;
  final String? nisn;
  final int? kelasId;
  final DateTime createdAt;

  const ManagedProfileModel({
    required this.id,
    this.fullName,
    required this.role,
    required this.status,
    this.nisn,
    this.kelasId,
    required this.createdAt,
  });

  factory ManagedProfileModel.fromJson(Map<String, dynamic> json) {
    return ManagedProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      role: json['role'] as String? ?? 'siswa',
      status: json['status'] as String? ?? 'aktif',
      nisn: json['nisn'] as String?,
      kelasId: (json['kelas_id'] as num?)?.toInt(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  ManagedProfile toEntity() {
    return ManagedProfile(
      id: id,
      fullName: fullName,
      role: UserRole.fromString(role),
      status: UserStatus.fromString(status),
      nisn: nisn,
      kelasId: kelasId,
      createdAt: createdAt,
    );
  }
}
