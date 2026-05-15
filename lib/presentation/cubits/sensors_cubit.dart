import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/data/repositories/location_repository.dart';
import 'package:test1/data/repositories/sensor_repository.dart';

part 'sensors_state.dart';

class SensorsCubit extends Cubit<SensorsState> {
  SensorsCubit() : super(const SensorsInitial());

  final _locationRepo = LocationRepository();
  final _sensorRepo = SensorRepository();

  Future<void> load() async {
    emit(const SensorsLoading());
    await _reload();
  }

  Future<void> addLocation(String name, String address) async {
    try {
      await _locationRepo.createLocation(name, address);
      await _reload();
    } catch (error, stackTrace) {
      log(
        'Failed to add location',
        name: 'SensorsCubit',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const SensorsError('Не вдалося додати локацію'));
    }
  }

  Future<void> deleteLocation(String id) async {
    try {
      await _locationRepo.deleteLocation(id);
      await _reload();
    } catch (error, stackTrace) {
      log(
        'Failed to delete location',
        name: 'SensorsCubit',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const SensorsError('Не вдалося видалити локацію'));
    }
  }

  Future<void> addSensor(
    String locationId,
    String name,
    String type,
    String unit,
  ) async {
    try {
      await _sensorRepo.createSensor(locationId, name, type, unit);
      await _reload();
    } catch (error, stackTrace) {
      log(
        'Failed to add sensor',
        name: 'SensorsCubit',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const SensorsError('Не вдалося додати сенсор'));
    }
  }

  Future<void> deleteSensor(String id) async {
    try {
      await _sensorRepo.deleteSensor(id);
      await _reload();
    } catch (error, stackTrace) {
      log(
        'Failed to delete sensor',
        name: 'SensorsCubit',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const SensorsError('Не вдалося видалити сенсор'));
    }
  }

  Future<void> _reload() async {
    try {
      final locations = await _locationRepo.getLocations();
      final allSensors = await _sensorRepo.getAllSensors();

      final Map<String, List<Map<String, dynamic>>> sensorsByLocation = {
        for (final loc in locations) loc['id'] as String: [],
      };
      for (final sensor in allSensors) {
        final locationId = sensor['location_id'] as String;
        sensorsByLocation.putIfAbsent(locationId, () => []).add(sensor);
      }

      emit(
        SensorsLoaded(
          locations: locations,
          sensorsByLocation: sensorsByLocation,
        ),
      );
    } catch (error, stackTrace) {
      log(
        'Failed to reload sensors data',
        name: 'SensorsCubit',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const SensorsError('Не вдалося завантажити дані'));
    }
  }
}
