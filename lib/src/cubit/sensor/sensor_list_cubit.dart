import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/src/data/api_client.dart';
import 'package:test1/src/domain/models/sensor.dart';

class SensorListCubit extends Cubit<List<Sensor>> {
  SensorListCubit() : super([]) {
    loadSensors();
  }

  Future<void> loadSensors() async {
    try {
      final sensors = await ApiClient.fetchSensors();
      emit(sensors);
    } catch (_) {
      emit([]);
    }
  }

  Future<void> addSensor(Sensor sensor) async {
    final created = await ApiClient.createSensor(sensor);
    emit([...state, created]);
  }

  Future<void> updateSensor(Sensor updated) async {
    await ApiClient.updateSensor(updated);
    emit(state.map((s) => s.id == updated.id ? updated : s).toList());
  }

  Future<void> deleteSensor(int id) async {
    await ApiClient.deleteSensor(id);
    emit(state.where((s) => s.id != id).toList());
  }
}
