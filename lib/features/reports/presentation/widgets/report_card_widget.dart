import 'package:flutter/material.dart';
import 'package:beranibicara/core/utils/date_time_format.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';
import 'package:beranibicara/features/reports/presentation/widgets/status_badge_widget.dart';
import 'package:beranibicara/features/reports/presentation/widgets/anonymous_indicator_widget.dart';

/// Report Card Widget - displays a report in a card format
class ReportCardWidget extends StatelessWidget {
  final Report report;
  final VoidCallback? onTap;
  final bool showReporter;

  const ReportCardWidget({
    super.key,
    required this.report,
    this.onTap,
    this.showReporter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title + Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title or "No Title"
                  Expanded(
                    child: Text(
                      report.title ?? 'Tanpa Judul',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badge
                  StatusBadgeWidget(status: report.status),
                ],
              ),
              
              const SizedBox(height: 12),

              // Description
              Text(
                report.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Meta information
              Row(
                children: [
                  // Date
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatAppDateTime(report.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  const SizedBox(width: 16),

                  // Anonymous indicator
                  AnonymousIndicatorWidget(isAnonymous: report.isAnonymous),

                  const Spacer(),

                  // Reporter name (staff list: TPPK, admin, guru)
                  if (showReporter &&
                      report.reporterName != null &&
                      !report.isAnonymous)
                    Flexible(
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              report.reporterName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty Reports Widget - shown when there are no reports
class EmptyReportsWidget extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyReportsWidget({
    super.key,
    this.message = 'Belum ada laporan',
    this.icon = Icons.report_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
