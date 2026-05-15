part of 'telemetry_data_cubit.dart';

abstract class TelemetryDataState {
  const TelemetryDataState();
}

class TelemetryInitial extends TelemetryDataState {
  const TelemetryInitial();
}

class TelemetryLoading extends TelemetryDataState {
  const TelemetryLoading();
}

class TelemetryLoaded extends TelemetryDataState {
  final List<Map<String, dynamic>> points;

  const TelemetryLoaded(this.points);
}

class TelemetryError extends TelemetryDataState {
  final String message;

  const TelemetryError(this.message);
}
