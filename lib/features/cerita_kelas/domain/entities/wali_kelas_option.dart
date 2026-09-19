import 'package:equatable/equatable.dart';

class WaliKelasOption extends Equatable {
  final int id;
  final int tingkat;
  final String jurusan;

  const WaliKelasOption({
    required this.id,
    required this.tingkat,
    required this.jurusan,
  });

  String get label => 'Kelas $tingkat $jurusan';

  @override
  List<Object?> get props => [id, tingkat, jurusan];
}
