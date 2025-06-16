part of 'connection_cubit.dart';

abstract class ConnectorState {}

class ConnectorInitial extends ConnectorState {}

class ConnectorLoading extends ConnectorState {}

class ConnectorConnected extends ConnectorState {}

class ConnectorDisconnected extends ConnectorState {}
