import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/reports/presentation/providers/report_notifier.dart';
import 'package:beranibicara/features/reports/presentation/widgets/report_card_widget.dart';
import 'package:beranibicara/shared/widgets/dashboard_app_bar_actions.dart';
import 'package:beranibicara/shared/widgets/empty_state_card.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  Future<void> _loadReports() async {
    final authNotifier = context.read<AuthNotifier>();
    final reportNotifier = context.read<ReportNotifier>();
    final user = authNotifier.user;

    if (user != null) {
      await reportNotifier.getReportsByReporter(user.id);
    }
  }

  Future<void> _refreshDashboard() => _loadReports();

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthNotifier>().user?.displayName ?? 'Siswa';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to Create Report screen with stack (can go back)
                      context.push(AppConstants.routeCreateReport);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Buat Laporan Baru'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.push(AppConstants.routeSocialization);
                    },
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text('Materi Sosialisasi'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.push(AppConstants.routeCeritaKelas);
                    },
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Cerita Kelas'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bagian Laporan Saya
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Laporan Saya',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // Navigate to Reports List with stack (can go back)
                          context.push(AppConstants.routeReports);
                        },
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Lihat Semua'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Display user's reports
                  Consumer<ReportNotifier>(
                    builder: (context, reportNotifier, child) {
                      final reports = reportNotifier.reports;
                      final isLoadingReports = reportNotifier.isLoading;

                      if (isLoadingReports) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (reports.isEmpty) {
                        // Empty state placeholder
                        return EmptyStateCard(
                          message: 'Anda belum membuat laporan.',
                          subtitle: 'Tap untuk lihat semua laporan',
                          onTap: () {
                            context.push(AppConstants.routeReports);
                          },
                        );
                      }

                      // Show up to 5 recent reports
                      final recentReports = reports.take(5).toList();

                      return Column(
                        children: recentReports
                            .map((report) => ReportCardWidget(
                                  report: report,
                                  showReporter: false,
                                  onTap: () {
                                    context.push(
                                      '${AppConstants.routeReports}/${report.id}',
                                    );
                                  },
                                ))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }
}