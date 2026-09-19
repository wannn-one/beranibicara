import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:beranibicara/core/constants/app_colors.dart';
import 'package:beranibicara/features/reports/domain/entities/report.dart';

enum ReportTrendRange { days7, days30, months12 }

class ReportTrendChart extends StatelessWidget {
  final List<Report> reports;
  final ReportTrendRange range;

  const ReportTrendChart({
    super.key,
    required this.reports,
    required this.range,
  });

  static const _weekdayShort = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];
  static const _monthShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  static const _monthLong = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  Widget build(BuildContext context) {
    final series = _buildSeries(reports, range);
    final maxY = series.spots.fold<double>(
      0,
      (max, spot) => spot.y > max ? spot.y : max,
    );
    final chartMaxY = maxY < 1 ? 1.0 : maxY;
    final yInterval = chartMaxY <= 5 ? 1.0 : (chartMaxY / 4).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${series.total} laporan dalam periode ini',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (series.spots.length - 1).toDouble(),
              minY: 0,
              maxY: chartMaxY + (yInterval / 2),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300),
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value > chartMaxY + 0.01) {
                        return const SizedBox.shrink();
                      }
                      if (value % 1 != 0) return const SizedBox.shrink();
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 || index >= series.labels.length) {
                        return const SizedBox.shrink();
                      }
                      if (!_shouldShowLabel(
                        index,
                        series.labels.length,
                        range,
                      )) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          series.labels[index],
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.round();
                      final label =
                          index >= 0 && index < series.fullLabels.length
                              ? series.fullLabels[index]
                              : '';
                      return LineTooltipItem(
                        '$label\n${spot.y.toInt()} laporan',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: series.spots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                  dotData: FlDotData(
                    show: range != ReportTrendRange.days30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static bool _shouldShowLabel(int index, int length, ReportTrendRange range) {
    switch (range) {
      case ReportTrendRange.days7:
        return true;
      case ReportTrendRange.days30:
        return index == 0 || index == length - 1 || index % 5 == 0;
      case ReportTrendRange.months12:
        return index == 0 || index == length - 1 || index % 2 == 0;
    }
  }

  static _TrendSeries _buildSeries(
    List<Report> reports,
    ReportTrendRange range,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fullDay = DateFormat('d MMM yyyy');

    switch (range) {
      case ReportTrendRange.days7:
        return _dailySeries(
          reports,
          today,
          7,
          (d) => _weekdayShort[d.weekday - 1],
          fullDay,
        );
      case ReportTrendRange.days30:
        return _dailySeries(
          reports,
          today,
          30,
          (d) => DateFormat('d/M').format(d),
          fullDay,
        );
      case ReportTrendRange.months12:
        return _monthlySeries(reports, today);
    }
  }

  static _TrendSeries _dailySeries(
    List<Report> reports,
    DateTime today,
    int days,
    String Function(DateTime) shortLabel,
    DateFormat fullFormat,
  ) {
    final buckets = List.generate(
      days,
      (i) => today.subtract(Duration(days: days - 1 - i)),
    );
    final counts = List<int>.filled(days, 0);
    final start = buckets.first;

    for (final report in reports) {
      final local = report.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (day.isBefore(start) || day.isAfter(today)) continue;
      final index = day.difference(start).inDays;
      if (index >= 0 && index < days) counts[index]++;
    }

    return _TrendSeries(
      spots: [
        for (var i = 0; i < days; i++)
          FlSpot(i.toDouble(), counts[i].toDouble()),
      ],
      labels: buckets.map(shortLabel).toList(),
      fullLabels: buckets.map((d) => fullFormat.format(d)).toList(),
      total: counts.fold(0, (sum, n) => sum + n),
    );
  }

  static _TrendSeries _monthlySeries(List<Report> reports, DateTime today) {
    final buckets = List.generate(12, (i) {
      return DateTime(today.year, today.month - (11 - i));
    });
    final counts = List<int>.filled(12, 0);
    final start = DateTime(buckets.first.year, buckets.first.month);

    for (final report in reports) {
      final local = report.createdAt.toLocal();
      final month = DateTime(local.year, local.month);
      if (month.isBefore(start) ||
          month.isAfter(DateTime(today.year, today.month))) {
        continue;
      }
      final index =
          (local.year - start.year) * 12 + (local.month - start.month);
      if (index >= 0 && index < 12) counts[index]++;
    }

    return _TrendSeries(
      spots: [
        for (var i = 0; i < 12; i++) FlSpot(i.toDouble(), counts[i].toDouble()),
      ],
      labels: buckets.map((d) => _monthShort[d.month - 1]).toList(),
      fullLabels: buckets
          .map((d) => '${_monthLong[d.month - 1]} ${d.year}')
          .toList(),
      total: counts.fold(0, (sum, n) => sum + n),
    );
  }
}

class _TrendSeries {
  final List<FlSpot> spots;
  final List<String> labels;
  final List<String> fullLabels;
  final int total;

  const _TrendSeries({
    required this.spots,
    required this.labels,
    required this.fullLabels,
    required this.total,
  });
}
