import 'package:flutter_bloc/flutter_bloc.dart';

part 'connection_state.dart';

class ConnectorCubit extends Cubit<ConnectorState> {
  ConnectorCubit() : super(ConnectorInitial());

  Future<void> toggleConnection(bool isOnline) async {
    if (!isOnline) return;

    emit(ConnectorLoading());
    await Future<void>.delayed(const Duration(seconds: 1));

    if (state is ConnectorConnected) {
      emit(ConnectorDisconnected());
    } else {
      emit(ConnectorConnected());
    }
  }

  void disconnect() => emit(ConnectorDisconnected());
}
