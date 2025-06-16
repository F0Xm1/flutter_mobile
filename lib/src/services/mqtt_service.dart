import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

typedef OnSensorData = void Function({
  int? temperature,
  int? humidity,
  int? pressure,
});

enum MqttCurrentConnectionState {
  idle,
  connecting,
  connected,
  disconnected,
  errorWhenConnecting,
}

enum MqttSubscriptionState { idle, subscribed }

class MQTTClientWrapper {
  final String host;
  final int port;
  final String clientIdentifier;
  final String? username;
  final String? password;

  OnSensorData? onData;

  MqttCurrentConnectionState connectionState = MqttCurrentConnectionState.idle;
  MqttSubscriptionState subscriptionState = MqttSubscriptionState.idle;

  MqttServerClient? _client;

  MQTTClientWrapper({
    required this.host,
    required String clientIdentifier,
    this.onData,
    this.port = 8883,
    String? clientId,
    this.username,
    this.password,
  }) : clientIdentifier = clientId ??
            'flutter_client_${DateTime.now().millisecondsSinceEpoch}';

  Future<void> prepareMqttClient() async {
    if (_client == null) {
      _setupMqttClient();
    }
    await _connectClient();
    if (connectionState == MqttCurrentConnectionState.connected) {
      _subscribeToTopic('sensor/temperature');
      _subscribeToTopic('sensor/humidity');
      _subscribeToTopic('sensor/pressure');
    }
  }

  void _setupMqttClient() {
    _client = MqttServerClient.withPort(host, clientIdentifier, port)
      ..secure = true
      ..securityContext = SecurityContext.defaultContext
      ..logging(on: false)
      ..keepAlivePeriod = 20
      ..onDisconnected = _onDisconnected
      ..onConnected = _onConnected
      ..onSubscribed = _onSubscribed
      ..setProtocolV311();
  }

  Future<void> _connectClient() async {
    connectionState = MqttCurrentConnectionState.connecting;

    final connMsg = MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    if (username != null && password != null) {
      connMsg.authenticateAs(username!, password!);
    }

    _client?.connectionMessage = connMsg;

    try {
      await _client?.connect();
    } on Exception {
      connectionState = MqttCurrentConnectionState.errorWhenConnecting;
      _client?.disconnect();
      return;
    }

    if (_client?.connectionStatus!.state == MqttConnectionState.connected) {
      connectionState = MqttCurrentConnectionState.connected;
    } else {
      connectionState = MqttCurrentConnectionState.errorWhenConnecting;
      _client?.disconnect();
    }
  }

  void _subscribeToTopic(String topic) {
    if (connectionState != MqttCurrentConnectionState.connected) return;

    _client?.subscribe(topic, MqttQos.atMostOnce);
    _client?.updates?.listen((messages) {
      for (final msg in messages) {
        final payload = MqttPublishPayload.bytesToStringAsString(
          (msg.payload as MqttPublishMessage).payload.message,
        );
        debugPrint('🔔 [${msg.topic}] → $payload');

        final int? value = int.tryParse(payload);
        if (value == null) continue;

        switch (msg.topic) {
          case 'sensor/temperature':
            onData?.call(temperature: value);
            break;
          case 'sensor/humidity':
            onData?.call(humidity: value);
            break;
          case 'sensor/pressure':
            onData?.call(pressure: value);
            break;
        }
      }
    });
  }

  void _onSubscribed(String topic) {
    subscriptionState = MqttSubscriptionState.subscribed;
    debugPrint('✅ Subscribed to $topic');
  }

  void _onDisconnected() {
    connectionState = MqttCurrentConnectionState.disconnected;
    debugPrint('❌ Disconnected from broker');
  }

  void _onConnected() {
    connectionState = MqttCurrentConnectionState.connected;
    debugPrint('✅ Connected to broker');
  }

  void disconnect() {
    _client?.disconnect();
    connectionState = MqttCurrentConnectionState.disconnected;
  }
}
