import 'package:flutter/material.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';

/// Status Badge Widget - displays report status with color coding
class StatusBadgeWidget extends StatelessWidget {
  final ReportStatus status;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const StatusBadgeWidget({
    super.key,
    required this.status,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status),
          width: 1,
        ),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: fontSize ?? 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.baru:
        return Colors.blue;
      case ReportStatus.diproses:
        return Colors.orange;
      case ReportStatus.selesai:
        return Colors.green;
      case ReportStatus.ditolak:
        return Colors.red;
      case ReportStatus.spam:
        return Colors.grey;
    }
  }

  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.baru:
        return 'Baru';
      case ReportStatus.diproses:
        return 'Diproses';
      case ReportStatus.selesai:
        return 'Selesai';
      case ReportStatus.ditolak:
        return 'Ditolak';
      case ReportStatus.spam:
        return 'Spam';
    }
  }
}
