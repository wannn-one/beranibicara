import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/features/admin/domain/entities/managed_kelas.dart';
import 'package:beranibicara/features/admin/presentation/providers/admin_notifier.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/reports/presentation/providers/report_notifier.dart';
import 'package:beranibicara/features/reports/presentation/widgets/report_card_widget.dart';
import 'package:beranibicara/shared/widgets/dashboard_app_bar_actions.dart';
import 'package:beranibicara/shared/widgets/empty_state_card.dart';

class DashboardTeacherScreen extends StatefulWidget {
  const DashboardTeacherScreen({super.key});

  @override
  State<DashboardTeacherScreen> createState() => _DashboardTeacherScreenState();
}

class _DashboardTeacherScreenState extends State<DashboardTeacherScreen> {
  bool _isLoadingWali = true;
  List<ManagedKelas> _assignedKelas = [];

  bool get _isWaliKelas => _assignedKelas.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoadingWali = true);

    final user = context.read<AuthNotifier>().user;
    final adminNotifier = context.read<AdminNotifier>();
    final reportNotifier = context.read<ReportNotifier>();

    await adminNotifier.loadKelas();
    if (!mounted) return;

    final assigned = user == null
        ? <ManagedKelas>[]
        : adminNotifier.kelasList
            .where((kelas) => kelas.waliKelasId == user.id)
            .toList();

    setState(() {
      _assignedKelas = assigned;
      _isLoadingWali = false;
    });

    if (assigned.isEmpty) {
      reportNotifier.clearReports();
      return;
    }

    await reportNotifier.getAllReports();
  }

  Future<void> _refreshDashboard() => _loadDashboard();

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthNotifier>().user?.displayName ?? 'Guru';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Wali Kelas'),
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
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),

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
                    const SizedBox(height: 24),

                    Text(
                      _isWaliKelas
                          ? 'Laporan dari ${_assignedKelas.map((k) => k.label).join(', ')}'
                          : 'Laporan dari Siswa Kelas Anda',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),

                    if (_isLoadingWali)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (!_isWaliKelas)
                      _buildNotWaliKelasCard()
                    else
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
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.description_outlined,
                                      size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  const Text(
                                      'Belum ada laporan dari siswa di kelas Anda'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Laporan dari siswa akan muncul di sini',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Show up to 5 recent reports
                        final recentReports = reports.take(5).toList();

                        return Column(
                          children: recentReports
                              .map((report) => ReportCardWidget(
                                    report: report,
                                    showReporter: true, // Teachers can see reporter name
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

  Widget _buildNotWaliKelasCard() {
    return const EmptyStateCard(
      icon: Icons.class_outlined,
      message: 'Anda belum menjadi wali kelas manapun',
      subtitle: 'Hubungi TPPK agar kelas Anda di-assign sebagai wali kelas.',
      messageStyle: TextStyle(fontWeight: FontWeight.w600),
    );
  }
}