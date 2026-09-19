import 'package:equatable/equatable.dart';

class AdminStats extends Equatable {
  final int usersTotal;
  final int usersSiswa;
  final int usersGuru;
  final int usersTppk;
  final int usersAdmin;
  final int usersAktif;
  final int usersBlocked;
  final int kelasTotal;
  final int reportsTotal;
  final Map<String, int> reportsByStatus;
  final int socializationTotal;

  const AdminStats({
    required this.usersTotal,
    required this.usersSiswa,
    required this.usersGuru,
    required this.usersTppk,
    required this.usersAdmin,
    required this.usersAktif,
    required this.usersBlocked,
    required this.kelasTotal,
    required this.reportsTotal,
    required this.reportsByStatus,
    required this.socializationTotal,
  });

  int reportStatus(String status) => reportsByStatus[status] ?? 0;

  @override
  List<Object?> get props => [
        usersTotal,
        usersSiswa,
        usersGuru,
        usersTppk,
        usersAdmin,
        usersAktif,
        usersBlocked,
        kelasTotal,
        reportsTotal,
        reportsByStatus,
        socializationTotal,
      ];
}
