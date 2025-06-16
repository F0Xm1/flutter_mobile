import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectionEvent {}

class ConnectionStarted extends ConnectionEvent {}

class ConnectionChanged extends ConnectionEvent {
  final ConnectivityResult connectivityResult;

  ConnectionChanged(this.connectivityResult);
}
