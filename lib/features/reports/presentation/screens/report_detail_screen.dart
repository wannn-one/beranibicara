import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:beranibicara/core/utils/date_time_format.dart';
import 'package:beranibicara/core/utils/url_utils.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';
import 'package:beranibicara/features/reports/presentation/providers/report_notifier.dart';
import 'package:beranibicara/features/reports/domain/entities/evidence.dart';
import 'package:beranibicara/features/reports/presentation/widgets/status_badge_widget.dart';
import 'package:beranibicara/features/reports/presentation/widgets/anonymous_indicator_widget.dart';
import 'package:beranibicara/features/reports/presentation/widgets/file_preview_widget.dart';
import 'package:beranibicara/features/balasan/presentation/widgets/balasan_chat_widget.dart';
import 'package:beranibicara/features/log_penanganan/presentation/widgets/log_penanganan_section.dart';
import 'package:beranibicara/shared/widgets/dialogs.dart';

/// Report Detail Screen - shows full report details
class ReportDetailScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadReport();
      }
    });
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reportNotifier = context.read<ReportNotifier>();
      await reportNotifier.getReportById(widget.reportId);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showStatusUpdateDialog(Report report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status Laporan'),
        content: RadioGroup<ReportStatus>(
          groupValue: report.status,
          onChanged: (ReportStatus? value) {
            if (value != null) {
              Navigator.pop(context);
              _updateStatus(value);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ReportStatus.values.map((status) {
              return RadioListTile<ReportStatus>(
                value: status,
                title: Text(status.value.toUpperCase()),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(ReportStatus newStatus) async {
    try {
      final reportNotifier = context.read<ReportNotifier>();
      final success = await reportNotifier.updateReportStatus(
        reportId: widget.reportId,
        newStatus: newStatus,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status berhasil diupdate'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reportNotifier.errorMessage ?? 'Gagal update status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDeleteConfirmation(Report report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Laporan?'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus laporan ini? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReport();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReport() async {
    try {
      final authNotifier = context.read<AuthNotifier>();
      final reportNotifier = context.read<ReportNotifier>();
      final userId = authNotifier.user?.id;

      if (userId == null) return;

      final success = await reportNotifier.deleteReport(
        reportId: widget.reportId,
        deletedBy: userId,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        // Pop back to reports list
        if (mounted) {
          context.pop();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reportNotifier.errorMessage ?? 'Gagal menghapus laporan',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openAttachment(Evidence attachment) async {
    if (attachment.fileType == FileType.image) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: InteractiveViewer(
            child: Image.network(
              attachment.fileUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Gagal memuat gambar'),
                );
              },
            ),
          ),
        ),
      );
      return;
    }

    await openExternalUrl(attachment.fileUrl);
  }

  Future<void> _confirmDeleteAttachment(Evidence attachment) async {
    final confirmed = await showConfirmDialog(
      context,
      'Hapus lampiran?',
      attachment.fileUrl.split('/').last,
      confirmText: 'Hapus',
    );

    if (confirmed != true || !mounted) return;

    final reportNotifier = context.read<ReportNotifier>();
    final success = await reportNotifier.deleteAttachment(attachment.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Lampiran dihapus'
              : (reportNotifier.errorMessage ?? 'Gagal menghapus lampiran'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final reportNotifier = context.watch<ReportNotifier>();
    final user = authNotifier.user;
    final report = reportNotifier.currentReport;

    if (_isLoading || reportNotifier.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Laporan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Laporan')),
        body: const Center(child: Text('Laporan tidak ditemukan')),
      );
    }

    final isReporter = user?.id == report.reporterId;
    final canManage =
        user?.role == UserRole.tppk || user?.role == UserRole.admin;
    final attachments = reportNotifier.currentReportEvidence;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        elevation: 0,
        actions: [
          // Edit button (only for reporter and editable status)
          if (isReporter && report.isEditable)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push('/reports/${report.id}/edit');
              },
              tooltip: 'Edit',
            ),

          // Update status button (only for TPPK/Admin)
          if (canManage)
            IconButton(
              icon: const Icon(Icons.update),
              onPressed: () => _showStatusUpdateDialog(report),
              tooltip: 'Update Status',
            ),

          // Delete button (TPPK/Admin only)
          if (canManage)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(report),
              tooltip: 'Hapus',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReport,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status and Anonymous badges
                      Row(
                        children: [
                          StatusBadgeWidget(
                            status: report.status,
                            fontSize: 14,
                          ),
                          const SizedBox(width: 8),
                          AnonymousIndicatorWidget(
                            isAnonymous: report.isAnonymous,
                            size: 16,
                          ),
                        ],
                      ),

                      if (!isReporter &&
                          report.reporterName != null &&
                          !report.isAnonymous) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                report.reporterName!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Title
                      if (report.title != null) ...[
                        Text(
                          report.title!,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Created date
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatAppDateTime(report.createdAt),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                      // Updated date
                      if (report.updatedAt != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.update,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Diupdate: ${formatAppDateTime(report.updatedAt!)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Description Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deskripsi',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        report.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lampiran',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (attachments.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.attach_file,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tidak ada lampiran',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        FilePreviewListWidget(
                          evidenceList: attachments,
                          onTap: _openAttachment,
                          showDelete: isReporter && report.isEditable,
                          onDelete: isReporter && report.isEditable
                              ? (attachment) =>
                                  _confirmDeleteAttachment(attachment)
                              : null,
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Balasan (Replies/Chat) Section
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline),
                          const SizedBox(width: 8),
                          Text(
                            'Balasan & Komunikasi',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 400, // Fixed height for chat
                      child: BalasanChatWidget(
                        reportId: int.parse(widget.reportId),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              LogPenangananSection(
                reportId: int.parse(widget.reportId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
