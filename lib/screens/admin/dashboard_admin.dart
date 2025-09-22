import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/screens/widgets/admin_drawer.dart';
import 'package:beranibicara/screens/widgets/stat_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:beranibicara/screens/admin/kelola_laporan.dart';

// Mengambil instance Supabase dari main.dart
final supabase = Supabase.instance.client;

class AdminDashboardScreen extends StatefulWidget {
  static const String routeName = '/admin-dashboard';
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;

  int _totalLaporan = 0;
  int _laporanBaru = 0;
  int _jumlahSiswa = 0;
  int _jumlahGuru = 0;

  List<FlSpot> _chartSpots = [];

  Map<String, double> _pieChartData = {};
  List<Map<String, dynamic>> _recentReports = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final results = await Future.wait<dynamic>([
        supabase.from('reports').count(CountOption.exact),
        supabase.from('reports').count(CountOption.exact).eq('status', 'baru'),
        supabase.from('profiles').count(CountOption.exact).eq('role', 'siswa'),
        supabase.from('profiles').count(CountOption.exact).eq('role', 'guru'),
        supabase
            .from('reports')
            .select('created_at')
            .gte('created_at', sevenDaysAgo.toIso8601String()),
        supabase.rpc('get_report_status_counts'),
        supabase
            .from('reports')
            .select('*, profiles(full_name)')
            .filter('status', 'in', '(baru,diproses)')
            .order('created_at', ascending: false)
            .limit(3),
      ]);

      if (mounted) {
        setState(() {
          _totalLaporan = results[0] as int;
          _laporanBaru = results[1] as int;
          _jumlahSiswa = results[2] as int;
          _jumlahGuru = results[3] as int;

          final rawReports = (results[4] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();

          final pieChartRawData = (results[5] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
          
          final dbRecentReports = (results[6] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();

          // Use real data from database
          _recentReports = dbRecentReports;
          _pieChartData = {
            for (var item in pieChartRawData)
              item['status']: (item['total'] as int).toDouble(),
          };
          _chartSpots = _processChartData(rawReports);
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil data: $error')));
        print('Gagal mengambil data: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<PieChartSectionData> _getPieChartSections() {
    return _pieChartData.entries.map((entry) {
      final color = _getStatusColor(entry.key);

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${entry.value.toInt()}', // Tampilkan jumlah
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  // Fungsi untuk membuat legenda pie chart
  List<Widget> _getPieChartIndicators() {
    return _pieChartData.entries.map((entry) {
      final color = _getStatusColor(entry.key);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(width: 16, height: 16, color: color),
            const SizedBox(width: 8),
            Text(_getStatusText(entry.key)), // Tampilkan nama status yang user-friendly
          ],
        ),
      );
    }).toList();
  }



  /// Memproses daftar laporan mentah menjadi titik data (FlSpot) untuk grafik
  List<FlSpot> _processChartData(List<Map<String, dynamic>> reports) {
    final Map<int, int> dailyCounts = {};
    final now = DateTime.now();

    // Inisialisasi 7 hari terakhir dengan hitungan 0
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      // Gunakan hari dalam tahun sebagai kunci unik untuk map
      final dayOfYear = int.parse(DateFormat('D').format(day));
      dailyCounts[dayOfYear] = 0;
    }

    // Hitung jumlah laporan untuk setiap hari
    for (var report in reports) {
      final reportDate = DateTime.parse(report['created_at']);
      final dayOfYear = int.parse(DateFormat('D').format(reportDate));
      if (dailyCounts.containsKey(dayOfYear)) {
        dailyCounts[dayOfYear] = dailyCounts[dayOfYear]! + 1;
      }
    }

    // Ubah map hitungan harian menjadi List<FlSpot>
    List<FlSpot> spots = [];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayOfYear = int.parse(DateFormat('D').format(day));
      spots.add(FlSpot(6 - i.toDouble(), dailyCounts[dayOfYear]!.toDouble()));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1.0,
      ),
      drawer: const AdminDrawer(currentRoute: AdminDashboardScreen.routeName),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Bagian Laporan Terbaru
                  const Text(
                    'Laporan Terbaru',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          spreadRadius: 1,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: _recentReports.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text('Belum ada laporan terbaru.'),
                            ),
                          )
                        : Column(
                            children: [
                              // Header dengan tombol "Lihat Semua"
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      '3 Laporan Terakhir',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, ManageReportsScreen.routeName);
                                      },
                                      child: const Text('Lihat Semua'),
                                    ),
                                  ],
                                ),
                              ),
                              // Daftar laporan
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _recentReports.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final report = _recentReports[index];
                                  final reporterName = report['profiles']?['full_name'] ?? 'Anonim';
                                  final createdAt = DateTime.parse(report['created_at']);
                                  final timeAgo = _getTimeAgo(createdAt);
                                  final status = report['status'] ?? 'baru';
                                  
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getStatusColor(status).withValues(alpha: 0.2),
                                      child: Icon(
                                        _getStatusIcon(status),
                                        color: _getStatusColor(status),
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      report['title'] ?? 'Laporan Tanpa Judul',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Oleh: $reporterName'),
                                        Text(
                                          timeAgo,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStatusText(status),
                                        style: TextStyle(
                                          color: _getStatusColor(status),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      // Navigasi ke detail laporan atau langsung ke halaman manage reports
                                      Navigator.pushNamed(
                                        context, 
                                        ManageReportsScreen.routeName,
                                        arguments: {'reportId': report['id']},
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Bagian Kartu Statistik (Grid 2x2)
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      StatCard(
                        title: 'Total Laporan',
                        value: _totalLaporan.toString(),
                        icon: Icons.description,
                        color: Colors.blue,
                      ),
                      StatCard(
                        title: 'Laporan Baru',
                        value: _laporanBaru.toString(),
                        icon: Icons.new_releases,
                        color: Colors.orange,
                      ),
                      StatCard(
                        title: 'Jumlah Siswa',
                        value: _jumlahSiswa.toString(),
                        icon: Icons.person,
                        color: Colors.green,
                      ),
                      StatCard(
                        title: 'Jumlah Guru',
                        value: _jumlahGuru.toString(),
                        icon: Icons.school,
                        color: Colors.purple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bagian Grafik (Placeholder)
                  const Text(
                    'Aktivitas Laporan Mingguan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          spreadRadius: 1,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: _chartSpots.isEmpty
                        ? const Center(
                            child: Text(
                              'Data laporan tidak cukup untuk menampilkan grafik.',
                            ),
                          )
                        : LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: true),
                              borderData: FlBorderData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final day = DateTime.now().subtract(
                                        Duration(days: 6 - value.toInt()),
                                      );
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(
                                          DateFormat('E').format(day),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _chartSpots,
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.blue.withValues(alpha: 0.3),
                                  ),
                                  dotData: const FlDotData(show: false),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Status Laporan Keseluruhan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          spreadRadius: 1,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _pieChartData.isEmpty
                              ? const Center(
                                  child: Text('Belum ada data laporan.'),
                                )
                              : PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                    sections: _getPieChartSections(),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _getPieChartIndicators(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'baru':
        return Colors.yellow[700]!;
      case 'diproses':
        return Colors.orange;
      case 'selesai':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'baru':
        return Icons.new_releases;
      case 'diproses':
        return Icons.pending;
      case 'selesai':
        return Icons.check_circle;
      case 'ditolak':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'baru':
        return 'Baru';
      case 'diproses':
        return 'Diproses';
      case 'selesai':
        return 'Selesai';
      case 'ditolak':
        return 'Ditolak';
      default:
        return 'Unknown';
    }
  }
}
