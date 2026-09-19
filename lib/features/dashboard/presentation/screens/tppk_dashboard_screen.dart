import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';
import 'package:beranibicara/features/reports/presentation/providers/report_notifier.dart';
import 'package:beranibicara/features/reports/presentation/widgets/report_trend_chart.dart';
import 'package:beranibicara/shared/widgets/dashboard_app_bar_actions.dart';

class DashboardTPPKScreen extends StatefulWidget {
  const DashboardTPPKScreen({super.key});

  @override
  State<DashboardTPPKScreen> createState() => _DashboardTPPKScreenState();
}

class _DashboardTPPKScreenState extends State<DashboardTPPKScreen> {
  bool _isLoadingStats = true;
  Map<String, int> _statusCounts = {};
  int _totalReports = 0;
  List<Report> _reports = [];
  ReportTrendRange _trendRange = ReportTrendRange.days7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatistics();
    });
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoadingStats = true;
    });

    final reportNotifier = context.read<ReportNotifier>();
    await reportNotifier.getAllReports();
    if (!mounted) return;

    final statusMap = <String, int>{};
    for (final report in reportNotifier.reports) {
      final status = report.status.value;
      statusMap[status] = (statusMap[status] ?? 0) + 1;
    }

    setState(() {
      _statusCounts = statusMap;
      _totalReports = reportNotifier.reports.length;
      _reports = List<Report>.from(reportNotifier.reports);
      _isLoadingStats = false;
    });
  }

  Future<void> _refreshDashboard() => _loadStatistics();

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthNotifier>().user?.displayName ?? 'TPPK';

    return Scaffold(
      appBar: AppBar(
        title: const Text('TPPK Dashboard'),
        actions: const [DashboardAppBarActions()],
      ),
      body: RefreshIndicator(
              onRefresh: _refreshDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang,\n$userName!',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),

                    // TPPK Actions
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push(AppConstants.routeReports);
                      },
                      icon: const Icon(Icons.report),
                      label: const Text('Kelola Laporan'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      onPressed: () {
                        context.push(AppConstants.routeSocialization);
                      },
                      icon: const Icon(Icons.campaign),
                      label: const Text('Sosialisasi'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      onPressed: () {
                        context.push(AppConstants.routeAdminKelas);
                      },
                      icon: const Icon(Icons.class_),
                      label: const Text('Kelola Kelas'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'Tren Laporan',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ReportTrendRange>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ReportTrendRange.days7,
                          label: Text('7 hari'),
                        ),
                        ButtonSegment(
                          value: ReportTrendRange.days30,
                          label: Text('1 bulan'),
                        ),
                        ButtonSegment(
                          value: ReportTrendRange.months12,
                          label: Text('1 tahun'),
                        ),
                      ],
                      selected: {_trendRange},
                      onSelectionChanged: (selected) {
                        setState(() => _trendRange = selected.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    _isLoadingStats
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Card(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
                              child: ReportTrendChart(
                                reports: _reports,
                                range: _trendRange,
                              ),
                            ),
                          ),
                    const SizedBox(height: 32),

                    // Report Statistics
                    Text(
                      'Statistik Laporan',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),

                    _isLoadingStats
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _buildStatistics(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatistics() {
    return Column(
      children: [
        // Total Reports Card
        _buildStatCard(
          title: 'Total Laporan',
          count: _totalReports,
          icon: Icons.description,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),

        // Status Cards Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildStatusCard(
              status: 'Baru',
              count: _statusCounts['baru'] ?? 0,
              icon: Icons.fiber_new,
              color: Colors.orange,
            ),
            _buildStatusCard(
              status: 'Diproses',
              count: _statusCounts['diproses'] ?? 0,
              icon: Icons.settings,
              color: Colors.orange,
            ),
            _buildStatusCard(
              status: 'Selesai',
              count: _statusCounts['selesai'] ?? 0,
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            _buildStatusCard(
              status: 'Ditolak',
              count: _statusCounts['ditolak'] ?? 0,
              icon: Icons.cancel,
              color: Colors.red,
            ),
            _buildStatusCard(
              status: 'Spam',
              count: _statusCounts['spam'] ?? 0,
              icon: Icons.report_problem,
              color: Colors.grey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
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

  Widget _buildStatusCard({
    required String status,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              status,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
