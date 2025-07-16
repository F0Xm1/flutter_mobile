import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/src/domain/models/sensor.dart';

class SensorEditorState {
  final int? id;
  final String name;
  final String type;

  SensorEditorState({
    this.id,
    this.name = '',
    this.type = '',
  });

  SensorEditorState copyWith({
    int? id,
    String? name,
    String? type,
  }) {
    return SensorEditorState(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }
}

class SensorEditorCubit extends Cubit<SensorEditorState> {
  SensorEditorCubit() : super(SensorEditorState());

  static SensorEditorCubit fromSensor(Sensor? sensor) {
    return SensorEditorCubit()
      ..emit(
        SensorEditorState(
          id: sensor?.id,
          name: sensor?.name ?? '',
          type: sensor?.type ?? '',
        ),
      );
  }

  void updateName(String name) => emit(state.copyWith(name: name));

  void updateType(String type) => emit(state.copyWith(type: type));

  bool get isValid =>
      state.name.trim().isNotEmpty && state.type.trim().isNotEmpty;

  Sensor toSensor() {
    return Sensor(
      id: state.id,
      name: state.name.trim(),
      type: state.type.trim(),
    );
  }
}
