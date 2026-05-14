import 'package:flutter/material.dart';

extension ColorWithValuesCompatibility on Color {
  Color withValues({double? alpha}) {
    if (alpha == null) return this;

    final alphaValue = (alpha * 255).round().clamp(0, 255).toInt();
    // ignore: deprecated_member_use
    return Color.fromARGB(alphaValue, red, green, blue);
  }
}
