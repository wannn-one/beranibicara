import 'package:equatable/equatable.dart';

/// User Role Enum (matching database enum)
enum UserRole {
  siswa('siswa'),
  guru('guru'),
  tppk('tppk'),
  admin('admin');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.siswa, // Default to siswa
    );
  }
}

/// User Status Enum (matching database enum)
enum UserStatus {
  aktif('aktif'),
  nonAktif('nonaktif'),
  blocked('blocked');

  final String value;
  const UserStatus(this.value);

  static UserStatus fromString(String value) {
    if (value == 'non_aktif' || value == 'nonaktif') {
      return UserStatus.nonAktif;
    }
    return UserStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => UserStatus.aktif,
    );
  }
}

/// User entity - Pure domain model
class User extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final UserRole role;
  final UserStatus status;
  final int? kelasId;
  final String? nisn;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    required this.status,
    this.kelasId,
    this.nisn,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if user is a student
  bool get isSiswa => role == UserRole.siswa;

  /// Check if user is a teacher
  bool get isGuru => role == UserRole.guru;

  /// Check if user is TPPK
  bool get isTPPK => role == UserRole.tppk;

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is active
  bool get isActive => status == UserStatus.aktif;

  /// Check if user is blocked
  bool get isBlocked => status == UserStatus.blocked;

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Pengguna';
  }

  /// Check if user has completed profile (has kelas if siswa)
  bool get hasCompletedProfile {
    if (isSiswa) {
      return kelasId != null;
    }
    return true; // TPPK, admin, guru (need to assign manually) don't need kelas
  }

  /// Copy with method for immutability
  User copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    UserStatus? status,
    int? kelasId,
    String? nisn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      status: status ?? this.status,
      kelasId: kelasId ?? this.kelasId,
      nisn: nisn ?? this.nisn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    role,
    status,
    kelasId,
    nisn,
    createdAt,
    updatedAt,
  ];
}
