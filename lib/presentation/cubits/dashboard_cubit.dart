import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:test1/data/repositories/event_repository.dart';
import 'package:test1/data/repositories/telemetry_repository.dart';
import 'package:test1/data/repositories/threshold_repository.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(const DashboardInitial());

  final _telemetryRepo = TelemetryRepository();
  final _thresholdRepo = ThresholdRepository();
  final _eventRepo = EventRepository();

  final _subscriptions = <StreamSubscription<Map<String, dynamic>>>[];
  StreamSubscription<Map<String, dynamic>>? _eventsSub;

  static const _envKeys = [
    'SENSOR_ID_TEMPERATURE',
    'SENSOR_ID_HUMIDITY',
    'SENSOR_ID_PRESSURE',
  ];

  DashboardSensorData _temp = const DashboardSensorData();
  DashboardSensorData _humidity = const DashboardSensorData();
  DashboardSensorData _pressure = const DashboardSensorData();
  String? _lastAlert;

  Future<void> startWatching() async {
    emit(const DashboardLoading());

    final ids = _envKeys.map((k) => dotenv.env[k] ?? '').toList();

    await Future.wait<void>([
      for (var i = 0; i < 3; i++)
        if (ids[i].isNotEmpty) _loadInitial(ids[i], i),
      _loadLastAlert(),
    ]);

    _emitLoaded();

    for (var i = 0; i < 3; i++) {
      if (ids[i].isNotEmpty) _subscribe(ids[i], i);
    }
    _subscribeToEvents();
  }

  Future<void> _loadInitial(String sensorId, int index) async {
    try {
      final telemetryFuture =
          _telemetryRepo.getLastTelemetry(sensorId, limit: 1);
      final thresholdFuture = _thresholdRepo.getThreshold(sensorId);

      final telemetry = await telemetryFuture;
      final threshold = await thresholdFuture;

      double? value;
      DateTime? lastUpdated;
      if (telemetry.isNotEmpty) {
        value = (telemetry.first['value'] as num).toDouble();
        final raw = telemetry.first['recorded_at'] as String?;
        lastUpdated = raw != null ? DateTime.parse(raw).toLocal() : null;
      }

      _setData(
        index,
        DashboardSensorData(
          value: value,
          lastUpdated: lastUpdated,
          minThreshold: (threshold?['min_value'] as num?)?.toDouble(),
          maxThreshold: (threshold?['max_value'] as num?)?.toDouble(),
        ),
      );
    } catch (error, stackTrace) {
      log(
        'Failed to load initial data for sensor $sensorId',
        name: 'DashboardCubit',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _loadLastAlert() async {
    try {
      final events = await _eventRepo.getEvents(limit: 1);
      if (events.isNotEmpty) {
        _lastAlert = _formatAlert(events.first);
      }
    } catch (error, stackTrace) {
      log(
        'Failed to load last alert',
        name: 'DashboardCubit',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _subscribeToEvents() {
    _eventsSub = _eventRepo.watchEvents().listen(
      (event) {
        _lastAlert = _formatAlert(event);
        _emitLoaded();
      },
      onError: (Object error, StackTrace stackTrace) {
        log(
          'Events stream error',
          name: 'DashboardCubit',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  String _formatAlert(Map<String, dynamic> event) {
    final sensorType = event['sensor_type'] as String;
    final value = (event['value'] as num).toDouble();
    final thresholdType = event['threshold_type'] as String;
    final thresholdValue = (event['threshold_value'] as num).toDouble();
    final unit = _unitFor(sensorType);
    final label = _labelFor(sensorType);
    final typeText =
        thresholdType == 'max' ? 'перевищено макс.' : 'нижче мін.';
    return '⚠️ $label: ${value.toStringAsFixed(1)}$unit — '
        '$typeText ${thresholdValue.toStringAsFixed(1)}$unit';
  }

  String _unitFor(String type) => switch (type) {
        'temperature' => '°C',
        'humidity' => '%',
        _ => 'hPa',
      };

  String _labelFor(String type) => switch (type) {
        'temperature' => 'Температура',
        'humidity' => 'Вологість',
        _ => 'Тиск',
      };

  void _subscribe(String sensorId, int index) {
    final sub = _telemetryRepo.watchTelemetry(sensorId).listen(
      (point) {
        final value = (point['value'] as num).toDouble();
        final raw = point['recorded_at'] as String?;
        final lastUpdated =
            raw != null ? DateTime.parse(raw).toLocal() : DateTime.now();

        final current = _getData(index);
        _setData(
          index,
          DashboardSensorData(
            value: value,
            lastUpdated: lastUpdated,
            minThreshold: current.minThreshold,
            maxThreshold: current.maxThreshold,
          ),
        );
        _emitLoaded();
      },
      onError: (Object error, StackTrace stackTrace) {
        log(
          'Stream error for sensor $sensorId',
          name: 'DashboardCubit',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    _subscriptions.add(sub);
  }

  DashboardSensorData _getData(int index) => switch (index) {
        0 => _temp,
        1 => _humidity,
        _ => _pressure,
      };

  void _setData(int index, DashboardSensorData data) {
    switch (index) {
      case 0:
        _temp = data;
      case 1:
        _humidity = data;
      default:
        _pressure = data;
    }
  }

  void _emitLoaded() {
    emit(
      DashboardLoaded(
        temperature: _temp,
        humidity: _humidity,
        pressure: _pressure,
        lastAlert: _lastAlert,
      ),
    );
  }

  @override
  Future<void> close() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    await _eventsSub?.cancel();
    return super.close();
  }
}
