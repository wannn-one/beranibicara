import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/features/admin/domain/entities/admin_stats.dart';
import 'package:beranibicara/features/admin/presentation/providers/admin_notifier.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  static const _statusLabels = <String, String>{
    'baru': 'Baru',
    'diproses': 'Diproses',
    'selesai': 'Selesai',
    'ditolak': 'Ditolak',
    'spam': 'Spam',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminNotifier>().loadStats();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AdminNotifier>();
    final stats = notifier.stats;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: notifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : stats == null
              ? Center(
                  child: Text(notifier.errorMessage ?? 'Statistik tidak tersedia'),
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<AdminNotifier>().loadStats(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _sectionTitle(context, 'Pengguna'),
                      _statTile('Total', stats.usersTotal),
                      _statTile('Siswa', stats.usersSiswa),
                      _statTile('Guru', stats.usersGuru),
                      _statTile('TPPK', stats.usersTppk),
                      _statTile('Admin', stats.usersAdmin),
                      _statTile('Aktif', stats.usersAktif),
                      _statTile('Diblokir', stats.usersBlocked),
                      const SizedBox(height: 16),
                      _sectionTitle(context, 'Sekolah'),
                      _statTile('Kelas', stats.kelasTotal),
                      _statTile('Artikel sosialisasi', stats.socializationTotal),
                      const SizedBox(height: 16),
                      _sectionTitle(context, 'Laporan'),
                      _statTile('Total (aktif)', stats.reportsTotal),
                      ..._reportStatusTiles(stats),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _statTile(String label, int value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  List<Widget> _reportStatusTiles(AdminStats stats) {
    final keys = <String>{
      ..._statusLabels.keys,
      ...stats.reportsByStatus.keys,
    };
    return keys
        .map(
          (key) => _statTile(
            _statusLabels[key] ?? key,
            stats.reportStatus(key),
          ),
        )
        .toList();
  }
}
