import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/src/bloc/connection/connection_bloc.dart';
import 'package:test1/src/bloc/connection/connection_state.dart' as connection;
import 'package:test1/src/cubit/station/connection_cubit.dart';
import 'package:test1/src/screens/home_page/smart_station_page.dart';
import 'package:test1/src/widgets/chipi_dizel_connector/chipi_dizel_connector.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    const accentPurple = Color(0xFF8A2BE2);

    final isOnline =
        context.watch<ConnectionBloc>().state is connection.ConnectionConnected;

    void showStationPicker(BuildContext context) async {
      final selectedStation = await showModalBottomSheet<Map<String, String>>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          final stations = [
            {
              'id': '1',
              'name': 'Станція температури',
              'metric': 'temperature',
            },
            {
              'id': '2',
              'name': 'Станція тиску повітря',
              'metric': 'pressure',
            },
            {
              'id': '3',
              'name': 'Станція вологості повітря',
              'metric': 'humidity',
            },
          ];

          return ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Оберіть станцію',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ...stations.map((station) {
                return ListTile(
                  title: Text(station['name']!),
                  onTap: () {
                    Navigator.pop(context, station);
                  },
                );
              }),
            ],
          );
        },
      );

      if (selectedStation != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => SmartStationPage(
              stationId: selectedStation['id']!,
              metric: selectedStation['metric'],
            ),
          ),
        );
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 30, horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.power_settings_new, size: 40, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Чіпідізєль Smart Station',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        accentPurple.withOpacity(0.3),
                        accentPurple.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: ChipiDizelConnector(
                      isOnline: isOnline,
                      onConnectionChanged: (connected) {
                        // Місце для додаткової логіки
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        BlocBuilder<ConnectorCubit, ConnectorState>(
          builder: (context, stationState) {
            final isConnected = stationState is ConnectorConnected;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isOnline && isConnected)
                    ? () => showStationPicker(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      (isOnline && isConnected) ? accentPurple : Colors.white10,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Перейти до станції',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'Ласкаво просимо до розумного дому!',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
