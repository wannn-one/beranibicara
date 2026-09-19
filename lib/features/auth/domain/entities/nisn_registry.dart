import 'package:equatable/equatable.dart';

/// NISN Registry Entity
class NisnRegistry extends Equatable {
  final String nisn;
  final String namaSiswa;
  final int? tingkat;
  final String? jurusan;
  final bool isRegistered;
  final String? userId;
  final DateTime createdAt;
  final DateTime? registeredAt;

  const NisnRegistry({
    required this.nisn,
    required this.namaSiswa,
    this.tingkat,
    this.jurusan,
    required this.isRegistered,
    this.userId,
    required this.createdAt,
    this.registeredAt,
  });

  /// Check if NISN is available for registration
  bool get isAvailable => !isRegistered && userId == null;

  @override
  List<Object?> get props => [
        nisn,
        namaSiswa,
        tingkat,
        jurusan,
        isRegistered,
        userId,
        createdAt,
        registeredAt,
      ];
}
