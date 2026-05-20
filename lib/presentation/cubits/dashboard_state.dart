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

  Map<String, dynamic> toJson() => {
        'value': value,
        'lastUpdated': lastUpdated?.toIso8601String(),
        'minThreshold': minThreshold,
        'maxThreshold': maxThreshold,
      };

  static DashboardSensorData fromJson(Map<String, dynamic> json) {
    return DashboardSensorData(
      value: (json['value'] as num?)?.toDouble(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      minThreshold: (json['minThreshold'] as num?)?.toDouble(),
      maxThreshold: (json['maxThreshold'] as num?)?.toDouble(),
    );
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
  final List<String> sensorTypes;
  final String? lastAlert;
  final List<Map<String, dynamic>> locations;
  final String? activeLocationId;
  final bool isFromCache;

  const DashboardLoaded({
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.locations,
    this.sensorTypes = const [],
    this.lastAlert,
    this.activeLocationId,
    this.isFromCache = false,
  });

  DashboardLoaded copyWith({
    DashboardSensorData? temperature,
    DashboardSensorData? humidity,
    DashboardSensorData? pressure,
    List<String>? sensorTypes,
    String? lastAlert,
    List<Map<String, dynamic>>? locations,
    String? activeLocationId,
    bool? isFromCache,
  }) {
    return DashboardLoaded(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      pressure: pressure ?? this.pressure,
      sensorTypes: sensorTypes ?? this.sensorTypes,
      lastAlert: lastAlert ?? this.lastAlert,
      locations: locations ?? this.locations,
      activeLocationId: activeLocationId ?? this.activeLocationId,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}
