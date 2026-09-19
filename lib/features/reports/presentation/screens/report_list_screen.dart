import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/reports/presentation/providers/report_notifier.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';
import 'package:beranibicara/features/reports/presentation/widgets/report_card_widget.dart';

/// Report List Screen - shows reports based on user role
class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  ReportStatus? _selectedStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadReports();
      }
    });
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authNotifier = context.read<AuthNotifier>();
      final reportNotifier = context.read<ReportNotifier>();
      final user = authNotifier.user;

      if (user == null) return;

      // Load reports based on user role
      switch (user.role) {
        case UserRole.siswa:
          // Students see only their own reports
          await reportNotifier.getReportsByReporter(user.id);
          break;

        case UserRole.guru:
        case UserRole.tppk:
        case UserRole.admin:
          // TPPK, Teachers, and Admins see all reports
          await reportNotifier.getAllReports(
            statusFilter: _selectedStatus,
          );
          break;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showFilterDialog() {
    final filterOptions = <MapEntry<ReportStatus?, String>>[
      const MapEntry(null, 'Semua'),
      const MapEntry(ReportStatus.baru, 'Baru'),
      const MapEntry(ReportStatus.diproses, 'Diproses'),
      const MapEntry(ReportStatus.selesai, 'Selesai'),
      const MapEntry(ReportStatus.ditolak, 'Ditolak'),
      const MapEntry(ReportStatus.spam, 'Spam'),
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Status'),
        content: RadioGroup<ReportStatus?>(
          groupValue: _selectedStatus,
          onChanged: (ReportStatus? value) {
            setState(() {
              _selectedStatus = value;
            });
            Navigator.pop(context);
            _loadReports();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: filterOptions.map((option) {
              return RadioListTile<ReportStatus?>(
                value: option.key,
                title: Text(option.value),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final reportNotifier = context.watch<ReportNotifier>();
    final user = authNotifier.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not authenticated')),
      );
    }

    final isStudent = user.role == UserRole.siswa;
    final reports = reportNotifier.reports;
    final isLoadingReports = reportNotifier.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(isStudent ? 'Laporan Saya' : 'Daftar Laporan'),
        elevation: 0,
        actions: [
          // Filter button (for non-students)
          if (!isStudent)
            IconButton(
              icon: Badge(
                isLabelVisible: _selectedStatus != null,
                child: const Icon(Icons.filter_list),
              ),
              onPressed: _showFilterDialog,
              tooltip: 'Filter',
            ),

          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading || isLoadingReports
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
              ? EmptyReportsWidget(
                  message: isStudent
                      ? 'Belum ada laporan.\nBuat laporan pertama Anda!'
                      : _selectedStatus != null
                          ? 'Tidak ada laporan dengan status ini'
                          : 'Belum ada laporan',
                )
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return ReportCardWidget(
                        report: report,
                        showReporter: !isStudent,
                        onTap: () {
                          // Navigate to report detail with stack (can go back)
                          context.push(
                            '${AppConstants.routeReports}/${report.id}',
                          );
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: isStudent
          ? FloatingActionButton.extended(
              onPressed: () {
                // Navigate to create report with stack (can go back)
                context.push(AppConstants.routeCreateReport);
              },
              icon: const Icon(Icons.add),
              label: const Text('Buat Laporan'),
            )
          : null,
    );
  }
}
