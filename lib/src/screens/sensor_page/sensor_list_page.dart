import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/src/cubit/sensor/sensor_list_cubit.dart';
import 'package:test1/src/domain/models/sensor.dart';
import 'package:test1/src/screens/sensor_page/sensor_editor_page.dart';

class SensorListPage extends StatelessWidget {
  const SensorListPage({super.key});

  static const darkBackground = Color(0xFF1A1B2D);
  static const accentPurple = Color(0xFF8A2BE2);
  static const lightPurple = Color(0xFFB19CD9);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SensorListCubit(),
      child: Scaffold(
        backgroundColor: darkBackground,
        body: Stack(
          children: [
            _background(),
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: _SensorListView(),
              ),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            backgroundColor: accentPurple,
            child: const Icon(Icons.add),
            onPressed: () async {
              final result = await SensorEditorPage.show(context);
              if (!context.mounted) return;
              if (result != null) {
                context.read<SensorListCubit>().addSensor(result);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _background() {
    return Stack(
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
        Positioned(
          top: -80,
          left: -50,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: lightPurple.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: accentPurple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _SensorListView extends StatelessWidget {
  const _SensorListView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            const Text(
              'Список сенсорів',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: BlocBuilder<SensorListCubit, List<Sensor>>(
            builder: (context, sensors) {
              if (sensors.isEmpty) {
                return const Center(
                  child: Text(
                    'Список порожній',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              return ListView.builder(
                itemCount: sensors.length,
                itemBuilder: (context, index) {
                  final sensor = sensors[index];
                  return Card(
                    color: Colors.white.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        sensor.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        sensor.type,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white70),
                            onPressed: () async {
                              final updated = await SensorEditorPage.show(
                                context,
                                sensor: sensor,
                              );
                              if (!context.mounted) return;
                              if (updated != null) {
                                context
                                    .read<SensorListCubit>()
                                    .updateSensor(updated);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => context
                                .read<SensorListCubit>()
                                .deleteSensor(sensor.id!),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
