import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/data/repositories/event_repository.dart';
import 'package:test1/data/repositories/location_repository.dart';
import 'package:test1/data/repositories/sensor_repository.dart';
import 'package:test1/data/repositories/telemetry_repository.dart';
import 'package:test1/data/repositories/threshold_repository.dart';
import 'package:test1/src/bloc/connection/connection_bloc.dart';
import 'package:test1/src/bloc/connection/connection_state.dart' as conn;
import 'package:test1/src/services/cache_service.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(ConnectionBloc connectionBloc)
      : super(const DashboardInitial()) {
    _connectionSub = connectionBloc.stream.listen(_onConnectionChanged);
  }

  final _locationRepo = LocationRepository();
  final _sensorRepo = SensorRepository();
  final _telemetryRepo = TelemetryRepository();
  final _thresholdRepo = ThresholdRepository();
  final _eventRepo = EventRepository();
  final _cacheService = CacheService();

  List<Map<String, dynamic>> _locations = [];
  String? _activeLocationId;
  List<Map<String, dynamic>> _sensors = [];

  DashboardSensorData _temp = const DashboardSensorData();
  DashboardSensorData _humidity = const DashboardSensorData();
  DashboardSensorData _pressure = const DashboardSensorData();
  String? _lastAlert;
  bool _isFromCache = false;

  final _subscriptions = <StreamSubscription<Map<String, dynamic>>>[];
  StreamSubscription<Map<String, dynamic>>? _eventsSub;
  StreamSubscription<conn.ConnectionState>? _connectionSub;

  Future<void> startWatching() async {
    emit(const DashboardLoading());

    try {
      _locations = await _locationRepo.getLocations();
    } catch (error, stackTrace) {
      log(
        'Failed to load locations',
        name: 'DashboardCubit',
        error: error,
        stackTrace: stackTrace,
      );
    }

    if (_activeLocationId == null && _locations.isNotEmpty) {
      _activeLocationId = _locations.first['id'] as String;
    }

    await Future.wait<void>([
      _loadSensorsAndData(),
      _loadLastAlert(),
    ]);

    _emitLoaded();
    _subscribeSensors();
    _subscribeToEvents();
  }

  Future<void> switchLocation(String locationId) async {
    if (_activeLocationId == locationId) return;

    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();

    _temp = const DashboardSensorData();
    _humidity = const DashboardSensorData();
    _pressure = const DashboardSensorData();
    _isFromCache = false;
    _activeLocationId = locationId;

    emit(const DashboardLoading());

    await _loadSensorsAndData();
    _emitLoaded();
    _subscribeSensors();
  }

  void _onConnectionChanged(conn.ConnectionState connectionState) {
    if (connectionState is conn.ConnectionDisconnected) {
      _isFromCache = true;
      if (state is DashboardLoaded) {
        _emitLoaded(isFromCache: true);
      } else {
        _loadFromCache();
      }
    } else if (connectionState is conn.ConnectionConnected && _isFromCache) {
      _isFromCache = false;
      _reload();
    }
  }

  Future<void> _loadFromCache() async {
    final locationId = _activeLocationId;
    if (locationId == null) return;

    final cached = await _cacheService.getLastValues(locationId);
    if (cached == null || isClosed) return;

    _temp = DashboardSensorData.fromJson(
      (cached['temperature'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    _humidity = DashboardSensorData.fromJson(
      (cached['humidity'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    _pressure = DashboardSensorData.fromJson(
      (cached['pressure'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    _lastAlert = cached['lastAlert'] as String?;

    _emitLoaded(isFromCache: true);
  }

  Future<void> _reload() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    await _eventsSub?.cancel();
    _eventsSub = null;

    _temp = const DashboardSensorData();
    _humidity = const DashboardSensorData();
    _pressure = const DashboardSensorData();

    emit(const DashboardLoading());

    await Future.wait<void>([
      _loadSensorsAndData(),
      _loadLastAlert(),
    ]);

    _emitLoaded();
    _subscribeSensors();
    _subscribeToEvents();
  }

  Future<void> _loadSensorsAndData() async {
    final locationId = _activeLocationId;
    if (locationId == null) return;

    try {
      _sensors = await _sensorRepo.getSensorsByLocation(locationId);
    } catch (error, stackTrace) {
      log(
        'Failed to load sensors for location $locationId',
        name: 'DashboardCubit',
        error: error,
        stackTrace: stackTrace,
      );
      _sensors = [];
      return;
    }

    await Future.wait([
      for (final sensor in _sensors) _loadInitial(sensor),
    ]);
  }

  Future<void> _loadInitial(Map<String, dynamic> sensor) async {
    final sensorId = sensor['id'] as String;
    final type = sensor['type'] as String;

    try {
      final telemetry =
          await _telemetryRepo.getLastTelemetry(sensorId, limit: 1);
      final threshold = await _thresholdRepo.getThreshold(sensorId);

      double? value;
      DateTime? lastUpdated;
      if (telemetry.isNotEmpty) {
        value = (telemetry.first['value'] as num).toDouble();
        final raw = telemetry.first['recorded_at'] as String?;
        lastUpdated = raw != null ? DateTime.parse(raw).toLocal() : null;
      }

      _setByType(
        type,
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

  void _subscribeSensors() {
    for (final sensor in _sensors) {
      _subscribe(sensor['id'] as String, sensor['type'] as String);
    }
  }

  void _subscribe(String sensorId, String type) {
    final sub = _telemetryRepo.watchTelemetry(sensorId).listen(
      (point) {
        final value = (point['value'] as num).toDouble();
        final raw = point['recorded_at'] as String?;
        final lastUpdated =
            raw != null ? DateTime.parse(raw).toLocal() : DateTime.now();

        final current = _getByType(type);
        _setByType(
          type,
          DashboardSensorData(
            value: value,
            lastUpdated: lastUpdated,
            minThreshold: current.minThreshold,
            maxThreshold: current.maxThreshold,
          ),
        );
        _isFromCache = false;
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

  DashboardSensorData _getByType(String type) => switch (type) {
        'temperature' => _temp,
        'humidity' => _humidity,
        _ => _pressure,
      };

  void _setByType(String type, DashboardSensorData data) {
    switch (type) {
      case 'temperature':
        _temp = data;
      case 'humidity':
        _humidity = data;
      default:
        _pressure = data;
    }
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

  void _emitLoaded({bool isFromCache = false}) {
    if (!isFromCache && _activeLocationId != null) {
      _cacheService
          .saveLastValues(_activeLocationId!, {
            'temperature': _temp.toJson(),
            'humidity': _humidity.toJson(),
            'pressure': _pressure.toJson(),
            'lastAlert': _lastAlert,
          })
          .ignore();
    }
    emit(
      DashboardLoaded(
        temperature: _temp,
        humidity: _humidity,
        pressure: _pressure,
        lastAlert: _lastAlert,
        locations: _locations,
        activeLocationId: _activeLocationId,
        isFromCache: isFromCache,
      ),
    );
  }

  @override
  Future<void> close() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    await _eventsSub?.cancel();
    await _connectionSub?.cancel();
    return super.close();
  }
}
