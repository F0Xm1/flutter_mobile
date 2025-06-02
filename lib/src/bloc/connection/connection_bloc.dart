import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:test1/src/bloc/connection/connection_event.dart';
import 'package:test1/src/bloc/connection/connection_state.dart';

class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionState> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectionBloc(this._connectivity) : super(ConnectionInitial()) {
    on<ConnectionStarted>(_onConnectionStarted);
    on<ConnectionChanged>(_onConnectionChanged);
  }

  Future<void> _onConnectionStarted(
    ConnectionStarted event,
    Emitter<ConnectionState> emit,
  ) async {
    final results = await _connectivity.checkConnectivity();
    final primary =
        results.isNotEmpty ? results.first : ConnectivityResult.none;
    add(ConnectionChanged(primary));

    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final primary =
            results.isNotEmpty ? results.first : ConnectivityResult.none;
        add(ConnectionChanged(primary));
      },
    );
  }

  void _onConnectionChanged(
    ConnectionChanged event,
    Emitter<ConnectionState> emit,
  ) {
    if (event.connectivityResult == ConnectivityResult.none) {
      emit(ConnectionDisconnected());
    } else {
      emit(ConnectionConnected());
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
