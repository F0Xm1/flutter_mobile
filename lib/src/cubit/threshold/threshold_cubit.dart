import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/data/repositories/threshold_repository.dart';

part 'threshold_state.dart';

class ThresholdCubit extends Cubit<ThresholdState> {
  ThresholdCubit() : super(const ThresholdInitial());

  final ThresholdRepository _repository = ThresholdRepository();

  Future<void> load(String sensorId) async {
    emit(const ThresholdLoading());
    try {
      final data = await _repository.getThreshold(sensorId);
      emit(
        ThresholdLoaded(
          min: (data?['min_value'] as num?)?.toDouble(),
          max: (data?['max_value'] as num?)?.toDouble(),
        ),
      );
    } catch (error, stackTrace) {
      log(
        'Failed to load threshold',
        name: 'ThresholdCubit',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const ThresholdError('Не вдалося завантажити пороги'));
    }
  }

  Future<void> save(String sensorId, double? min, double? max) async {
    emit(const ThresholdLoading());
    try {
      await _repository.upsertThreshold(sensorId, min, max);
      emit(ThresholdLoaded(min: min, max: max));
    } catch (error, stackTrace) {
      log(
        'Failed to save threshold',
        name: 'ThresholdCubit',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const ThresholdError('Не вдалося зберегти пороги'));
    }
  }
}
