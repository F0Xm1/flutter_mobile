import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TelemetryChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> points;
  final String unit;

  const TelemetryChartWidget({
    required this.points,
    required this.unit,
    super.key,
  });

  Color get _lineColor {
    switch (unit) {
      case '°C':
        return Colors.redAccent;
      case '%':
        return Colors.blueAccent;
      case 'hPa':
        return Colors.greenAccent;
      default:
        return Colors.purpleAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayPoints =
        points.length > 50 ? points.sublist(points.length - 50) : points;

    if (displayPoints.isEmpty) {
      return const Center(
        child: Text(
          'Немає даних для відображення',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final spots = displayPoints.asMap().entries.map((entry) {
      final value = (entry.value['value'] as num).toDouble();
      return FlSpot(entry.key.toDouble(), value);
    }).toList();

    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b) - 1;
    final maxY = values.reduce((a, b) => a > b ? a : b) + 1;

    final color = _lineColor;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.15),
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
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
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
          border: Border.all(color: Colors.white24),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.black87,
            getTooltipItems: (spots) => spots
                .map(
                  (spot) => LineTooltipItem(
                    '${spot.y.toStringAsFixed(2)} $unit',
                    const TextStyle(color: Colors.white, fontSize: 12),
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
