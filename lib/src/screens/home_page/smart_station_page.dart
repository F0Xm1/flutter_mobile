import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test1/src/bloc/connection/connection_bloc.dart';
import 'package:test1/src/bloc/connection/connection_state.dart' as conn;
import 'package:test1/src/cubit/station/station_data_cubit.dart';
import 'package:test1/src/screens/home_page/smart_station_content.dart';
import 'package:test1/src/screens/scanner/qr_scanner_screen.dart';
import 'package:test1/src/services/mqtt_service.dart';
import 'package:test1/src/widgets/dialogs/logout_confirmation_dialog.dart';

class SmartStationPage extends StatelessWidget {
  final String stationId;
  final String? metric;

  SmartStationPage({required this.stationId, super.key, this.metric});

  final MQTTClientWrapper _mqttClient = MQTTClientWrapper(
    host: 'URl',
    clientIdentifier: 'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
    username: 'dotem',
    password: 'PASS',
  );

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBackground = Color(0xFF1A1B2D);

    return BlocProvider(
      create: (context) {
        final cubit = StationDataCubit();
        _mqttClient.onData = cubit.updateSensorData;

        final connection = context.read<ConnectionBloc>().state;
        if (connection is conn.ConnectionConnected) {
          _mqttClient.prepareMqttClient();
        }

        Future<void>.delayed(const Duration(seconds: 1), () {
          if (_mqttClient.connectionState !=
              MqttCurrentConnectionState.connected) {
            _mqttClient.prepareMqttClient();
          }
        });

        return cubit;
      },
      child: BlocListener<ConnectionBloc, conn.ConnectionState>(
        listener: (context, state) {
          if (state is conn.ConnectionConnected) {
            _mqttClient.prepareMqttClient();
          } else if (state is conn.ConnectionDisconnected) {
            _mqttClient.disconnect();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: darkBackground,
            foregroundColor: Colors.white,
            title: const Text('Станція Чіпідізєль'),
            actions: [
              IconButton(
                icon: const Icon(Icons.photo_camera),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const QRScannerScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.exit_to_app),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => LogoutConfirmationDialog(
                      onConfirm: () => _logout(context),
                    ),
                  );
                },
              ),
            ],
          ),
          backgroundColor: darkBackground,
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [darkBackground, Color(0xFF25274D)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              SafeArea(
                child: SmartStationContent(metric: metric),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
