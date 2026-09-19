import 'package:equatable/equatable.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';

class ManagedProfile extends Equatable {
  final String id;
  final String? fullName;
  final UserRole role;
  final UserStatus status;
  final String? nisn;
  final int? kelasId;
  final DateTime createdAt;

  const ManagedProfile({
    required this.id,
    this.fullName,
    required this.role,
    required this.status,
    this.nisn,
    this.kelasId,
    required this.createdAt,
  });

  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty) ? fullName! : 'Tanpa nama';

  @override
  List<Object?> get props =>
      [id, fullName, role, status, nisn, kelasId, createdAt];
}
