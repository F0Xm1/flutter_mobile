import 'package:flutter_bloc/flutter_bloc.dart';

part 'station_data_state.dart';

class StationDataCubit extends Cubit<StationDataState> {
  StationDataCubit()
      : super(
          const StationDataUpdated(
            temperature: 0,
            humidity: 0,
            pressure: 0,
          ),
        );

  void updateSensorData({
    int? temperature,
    int? humidity,
    int? pressure,
  }) {
    final current = state as StationDataUpdated;
    emit(
      current.copyWith(
        temperature: temperature,
        humidity: humidity,
        pressure: pressure,
      ),
    );
  }
}
