import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/data/repositories/telemetry_repository.dart';

part 'telemetry_data_state.dart';

class TelemetryDataCubit extends Cubit<TelemetryDataState> {
  TelemetryDataCubit() : super(const TelemetryInitial());

  final TelemetryRepository _repository = TelemetryRepository();
  StreamSubscription<Map<String, dynamic>>? _subscription;
  String? _currentSensorId;

  static const int _maxPoints = 100;

  Future<void> loadAndWatch(String sensorId) async {
    if (_currentSensorId == sensorId) return;
    _currentSensorId = sensorId;

    await _subscription?.cancel();
    _subscription = null;

    emit(const TelemetryLoading());

    try {
      final history = await _repository.getLastTelemetry(sensorId);
      // history is ordered descending — reverse so oldest first
      final points = List<Map<String, dynamic>>.from(history.reversed);
      emit(TelemetryLoaded(points));

      _subscription = _repository
          .watchTelemetry(sensorId)
          .listen(
        (point) {
          final current = state;
          if (current is TelemetryLoaded) {
            final updated = [...current.points, point];
            if (updated.length > _maxPoints) {
              final trimmed = updated.sublist(updated.length - _maxPoints);
              emit(TelemetryLoaded(trimmed));
            } else {
              emit(TelemetryLoaded(updated));
            }
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          log(
            'Telemetry stream error',
            name: 'TelemetryDataCubit',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );
    } catch (error, stackTrace) {
      log(
        'Failed to load telemetry',
        name: 'TelemetryDataCubit',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const TelemetryError('Не вдалося завантажити дані телеметрії'));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
