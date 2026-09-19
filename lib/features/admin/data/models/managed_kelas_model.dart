import 'package:beranibicara/features/admin/domain/entities/managed_kelas.dart';

class ManagedKelasModel {
  final int id;
  final int tingkat;
  final String jurusan;
  final String? waliKelasId;
  final String? waliKelasName;

  const ManagedKelasModel({
    required this.id,
    required this.tingkat,
    required this.jurusan,
    this.waliKelasId,
    this.waliKelasName,
  });

  factory ManagedKelasModel.fromJson(Map<String, dynamic> json) {
    final wali = json['wali'];
    return ManagedKelasModel(
      id: (json['id'] as num).toInt(),
      tingkat: (json['tingkat'] as num).toInt(),
      jurusan: json['jurusan'] as String,
      waliKelasId: json['wali_kelas_id'] as String?,
      waliKelasName: wali is Map ? wali['full_name'] as String? : null,
    );
  }

  ManagedKelas toEntity() {
    return ManagedKelas(
      id: id,
      tingkat: tingkat,
      jurusan: jurusan,
      waliKelasId: waliKelasId,
      waliKelasName: waliKelasName,
    );
  }
}
