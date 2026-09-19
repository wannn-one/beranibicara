import 'package:equatable/equatable.dart';

/// School class entity — matches public.kelas
class Kelas extends Equatable {
  final int id;
  final int tingkat;
  final String jurusan;

  const Kelas({
    required this.id,
    required this.tingkat,
    required this.jurusan,
  });

  String get label => 'Kelas $tingkat $jurusan';

  @override
  List<Object?> get props => [id, tingkat, jurusan];
}
