import 'package:equatable/equatable.dart';

class ManagedKelas extends Equatable {
  final int id;
  final int tingkat;
  final String jurusan;
  final String? waliKelasId;
  final String? waliKelasName;

  const ManagedKelas({
    required this.id,
    required this.tingkat,
    required this.jurusan,
    this.waliKelasId,
    this.waliKelasName,
  });

  String get label => 'Kelas $tingkat $jurusan';

  @override
  List<Object?> get props => [id, tingkat, jurusan, waliKelasId, waliKelasName];
}
