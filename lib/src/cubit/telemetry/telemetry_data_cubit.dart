import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/data/repositories/telemetry_repository.dart';
import 'package:test1/src/services/push_mess/fcm_service.dart';

part 'telemetry_data_state.dart';

class TelemetryDataCubit extends Cubit<TelemetryDataState> {
  TelemetryDataCubit({required this.label, required this.unit})
      : super(const TelemetryInitial());

  final String label;
  final String unit;

  final TelemetryRepository _repository = TelemetryRepository();
  StreamSubscription<Map<String, dynamic>>? _subscription;
  String? _currentSensorId;

  double? _minThreshold;
  double? _maxThreshold;
  DateTime? _lastNotification;

  static const int _maxPoints = 100;
  static const _notificationCooldown = Duration(seconds: 30);

  void updateThreshold(double? min, double? max) {
    _minThreshold = min;
    _maxThreshold = max;
  }

  Future<void> loadAndWatch(String sensorId) async {
    if (_currentSensorId == sensorId) return;
    _currentSensorId = sensorId;

    await _subscription?.cancel();
    _subscription = null;

    emit(const TelemetryLoading());

    try {
      final history = await _repository.getLastTelemetry(sensorId);
      final points = List<Map<String, dynamic>>.from(history.reversed);
      emit(TelemetryLoaded(points));

      _subscription = _repository.watchTelemetry(sensorId).listen(
        (point) {
          final current = state;
          if (current is TelemetryLoaded) {
            final updated = [...current.points, point];
            final trimmed = updated.length > _maxPoints
                ? updated.sublist(updated.length - _maxPoints)
                : updated;
            emit(TelemetryLoaded(trimmed));
            _checkThreshold((point['value'] as num).toDouble());
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

  void _checkThreshold(double value) {
    final now = DateTime.now();
    final last = _lastNotification;
    if (last != null && now.difference(last) < _notificationCooldown) return;

    final max = _maxThreshold;
    final min = _minThreshold;

    final valueStr = value.toStringAsFixed(1);
    String? body;
    if (max != null && value > max) {
      body = '$valueStr$unit перевищує максимум'
          ' ${max.toStringAsFixed(1)}$unit';
    } else if (min != null && value < min) {
      body = '$valueStr$unit нижче мінімуму'
          ' ${min.toStringAsFixed(1)}$unit';
    }

    if (body != null) {
      _lastNotification = now;
      FCMService.showLocalNotification('⚠️ $label', body);
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
