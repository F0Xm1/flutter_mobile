part of 'dashboard_cubit.dart';

class DashboardSensorData {
  final double? value;
  final DateTime? lastUpdated;
  final double? minThreshold;
  final double? maxThreshold;

  const DashboardSensorData({
    this.value,
    this.lastUpdated,
    this.minThreshold,
    this.maxThreshold,
  });

  bool get isExceeded {
    if (value == null) return false;
    final max = maxThreshold;
    final min = minThreshold;
    if (max != null && value! > max) return true;
    if (min != null && value! < min) return true;
    return false;
  }

  DashboardSensorData copyWith({
    double? value,
    DateTime? lastUpdated,
    double? minThreshold,
    double? maxThreshold,
  }) {
    return DashboardSensorData(
      value: value ?? this.value,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      minThreshold: minThreshold ?? this.minThreshold,
      maxThreshold: maxThreshold ?? this.maxThreshold,
    );
  }
}

abstract class DashboardState {
  const DashboardState();
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardSensorData temperature;
  final DashboardSensorData humidity;
  final DashboardSensorData pressure;
  final String? lastAlert;

  const DashboardLoaded({
    required this.temperature,
    required this.humidity,
    required this.pressure,
    this.lastAlert,
  });

  DashboardLoaded copyWith({
    DashboardSensorData? temperature,
    DashboardSensorData? humidity,
    DashboardSensorData? pressure,
    String? lastAlert,
  }) {
    return DashboardLoaded(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      pressure: pressure ?? this.pressure,
      lastAlert: lastAlert ?? this.lastAlert,
    );
  }
}
