import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/data/repositories/event_repository.dart';
import 'package:test1/data/repositories/location_repository.dart';
import 'package:test1/data/repositories/sensor_repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileInitial());

  Future<void> load() async {
    emit(ProfileLoading());
    try {
      final locationsFuture = LocationRepository().getLocations();
      final sensorsFuture = SensorRepository().getAllSensors();
      final countFuture = EventRepository().getTodayEventsCount();

      final locations = await locationsFuture;
      final sensors = await sensorsFuture;
      final todayEventCount = await countFuture;

      emit(ProfileLoaded(
        locationCount: locations.length,
        sensorCount: sensors.length,
        todayEventCount: todayEventCount,
      ),);
    } catch (error, stackTrace) {
      log(
        'Failed to load profile stats',
        name: 'ProfileCubit',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const ProfileError('Не вдалося завантажити дані профілю'));
    }
  }
}
