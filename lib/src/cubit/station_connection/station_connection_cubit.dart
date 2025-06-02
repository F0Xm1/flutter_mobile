import 'package:flutter_bloc/flutter_bloc.dart';

part 'station_connection_state.dart';

class StationConnectionCubit extends Cubit<StationConnectionState> {
  StationConnectionCubit({bool initialConnected = false})
      : super(initialConnected ? StationConnected() : StationDisconnected());

  void setConnected(bool connected) => emit(
        connected ? StationConnected() : StationDisconnected(),
      );
}
