import 'package:flutter/material.dart';
import 'package:test1/core/app_colors.dart';
import 'package:test1/presentation/cubits/dashboard_cubit.dart';

class SensorCard extends StatelessWidget {
  final String label;
  final String unit;
  final IconData icon;
  final DashboardSensorData data;

  const SensorCard({
    required this.label,
    required this.unit,
    required this.icon,
    required this.data,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final exceeded = data.isExceeded;
    final value = data.value;

    final bgColor = exceeded
        ? Colors.red.withValues(alpha: 0.18)
        : AppColors.orange.withValues(alpha: 0.08);
    final borderColor = exceeded
        ? Colors.redAccent.withValues(alpha: 0.55)
        : AppColors.orange.withValues(alpha: 0.35);
    final valueColor = exceeded ? Colors.redAccent : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.orangeWarm, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (exceeded)
                const Icon(
                  Icons.warning_amber,
                  color: Colors.redAccent,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: value != null
                ? Text(
                    '${value.toStringAsFixed(1)} $unit',
                    key: ValueKey('${value.toStringAsFixed(1)}_$unit'),
                    style: TextStyle(
                      color: valueColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Text(
                    '— $unit',
                    key: const ValueKey('empty'),
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 24,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
