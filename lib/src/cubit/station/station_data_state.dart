part of 'station_data_cubit.dart';

abstract class StationDataState {
  const StationDataState();
}

class StationDataUpdated extends StationDataState {
  final int temperature;
  final int humidity;
  final int pressure;

  const StationDataUpdated({
    required this.temperature,
    required this.humidity,
    required this.pressure,
  }) : super();

  StationDataUpdated copyWith({
    int? temperature,
    int? humidity,
    int? pressure,
  }) {
    return StationDataUpdated(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      pressure: pressure ?? this.pressure,
    );
  }
}
