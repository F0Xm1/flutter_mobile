import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:test1/core/app_colors.dart';

class TelemetryChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> points;
  final String unit;
  final double? minThreshold;
  final double? maxThreshold;

  const TelemetryChartWidget({
    required this.points,
    required this.unit,
    this.minThreshold,
    this.maxThreshold,
    super.key,
  });

  Color get _lineColor => switch (unit) {
        '°C'  => AppColors.orange,
        '%'   => AppColors.amber,
        'hPa' => AppColors.orangeWarm,
        _     => AppColors.orange,
      };

  @override
  Widget build(BuildContext context) {
    final displayPoints =
        points.length > 50 ? points.sublist(points.length - 50) : points;

    if (displayPoints.isEmpty) {
      return const Center(
        child: Text(
          'Немає даних для відображення',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    final spots = displayPoints.asMap().entries.map((entry) {
      final value = (entry.value['value'] as num).toDouble();
      return FlSpot(entry.key.toDouble(), value);
    }).toList();

    final values = spots.map((s) => s.y).toList();
    var minY = values.reduce((a, b) => a < b ? a : b) - 1;
    var maxY = values.reduce((a, b) => a > b ? a : b) + 1;

    if (minThreshold != null && minThreshold! - 1 < minY) {
      minY = minThreshold! - 1;
    }
    if (maxThreshold != null && maxThreshold! + 1 > maxY) {
      maxY = maxThreshold! + 1;
    }

    final color = _lineColor;

    final thresholdLines = <HorizontalLine>[
      if (maxThreshold != null)
        HorizontalLine(
          y: maxThreshold!,
          color: Colors.redAccent,
          strokeWidth: 1.5,
          dashArray: [6, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            style: const TextStyle(color: Colors.redAccent, fontSize: 9),
            labelResolver: (line) =>
                'max: ${line.y.toStringAsFixed(1)} $unit',
          ),
        ),
      if (minThreshold != null)
        HorizontalLine(
          y: minThreshold!,
          color: Colors.blueAccent,
          strokeWidth: 1.5,
          dashArray: [6, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.bottomRight,
            style: const TextStyle(color: Colors.blueAccent, fontSize: 9),
            labelResolver: (line) =>
                'min: ${line.y.toStringAsFixed(1)} $unit',
          ),
        ),
    ];

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        extraLinesData: ExtraLinesData(horizontalLines: thresholdLines),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '${value.toStringAsFixed(1)} $unit',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.border),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.border,
            strokeWidth: 0.8,
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.bgElevated,
            getTooltipItems: (spots) => spots
                .map(
                  (spot) => LineTooltipItem(
                    '${spot.y.toStringAsFixed(2)} $unit',
                    TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 300),
    );
  }
}
