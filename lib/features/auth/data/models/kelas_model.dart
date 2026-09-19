import 'package:beranibicara/features/auth/domain/entities/kelas.dart';

class KelasModel {
  final int id;
  final int tingkat;
  final String jurusan;

  const KelasModel({
    required this.id,
    required this.tingkat,
    required this.jurusan,
  });

  factory KelasModel.fromJson(Map<String, dynamic> json) {
    return KelasModel(
      id: (json['id'] as num).toInt(),
      tingkat: (json['tingkat'] as num).toInt(),
      jurusan: json['jurusan'] as String,
    );
  }

  Kelas toEntity() {
    return Kelas(id: id, tingkat: tingkat, jurusan: jurusan);
  }
}
