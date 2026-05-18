import 'dart:async';

import 'package:flutter/material.dart';
import 'package:test1/core/app_colors.dart';

class BackendStatusWidget extends StatefulWidget {
  final DateTime? lastUpdated;

  const BackendStatusWidget({required this.lastUpdated, super.key});

  @override
  State<BackendStatusWidget> createState() => _BackendStatusWidgetState();
}

class _BackendStatusWidgetState extends State<BackendStatusWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = widget.lastUpdated;

    if (last == null) {
      return const _StatusChip(
        text: 'Очікування даних від симулятора...',
        color: AppColors.amber,
        isWarning: true,
      );
    }

    final age = DateTime.now().difference(last);

    if (age.inSeconds > 30) {
      return _StatusChip(
        text: 'Немає даних від симулятора (${age.inSeconds} с тому)',
        color: AppColors.amber,
        isWarning: true,
      );
    }

    return _StatusChip(
      text: 'Онлайн, оновлено ${age.inSeconds} с тому',
      color: AppColors.orangeWarm,
      isWarning: false,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  final bool isWarning;

  const _StatusChip({
    required this.text,
    required this.color,
    required this.isWarning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWarning ? Icons.warning_amber_rounded : Icons.circle,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
