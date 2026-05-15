part of 'sensors_cubit.dart';

abstract class SensorsState {
  const SensorsState();
}

class SensorsInitial extends SensorsState {
  const SensorsInitial();
}

class SensorsLoading extends SensorsState {
  const SensorsLoading();
}

class SensorsLoaded extends SensorsState {
  final List<Map<String, dynamic>> locations;
  final Map<String, List<Map<String, dynamic>>> sensorsByLocation;

  const SensorsLoaded({
    required this.locations,
    required this.sensorsByLocation,
  });
}

class SensorsError extends SensorsState {
  final String message;

  const SensorsError(this.message);
}
