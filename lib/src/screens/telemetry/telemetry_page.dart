import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:test1/src/cubit/telemetry/telemetry_data_cubit.dart';
import 'package:test1/src/cubit/threshold/threshold_cubit.dart';
import 'package:test1/src/widgets/telemetry_chart_widget.dart';
import 'package:test1/src/widgets/threshold_settings_widget.dart';

class TelemetryPage extends StatefulWidget {
  const TelemetryPage({super.key});

  @override
  State<TelemetryPage> createState() => _TelemetryPageState();
}

class _TelemetryPageState extends State<TelemetryPage>
    with SingleTickerProviderStateMixin {
  static const _darkBackground = Color(0xFF1A1B2D);

  static const _labels = ['Температура', 'Вологість', 'Тиск'];
  static const _units = ['°C', '%', 'hPa'];
  static const _envKeys = [
    'SENSOR_ID_TEMPERATURE',
    'SENSOR_ID_HUMIDITY',
    'SENSOR_ID_PRESSURE',
  ];

  late final TabController _tabController;
  late final List<String> _sensorIds;
  late final List<TelemetryDataCubit> _telemetryCubits;
  late final List<ThresholdCubit> _thresholdCubits;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _sensorIds = _envKeys.map((k) => dotenv.env[k] ?? '').toList();

    _telemetryCubits = List.generate(
      3,
      (i) => TelemetryDataCubit(label: _labels[i], unit: _units[i]),
    );
    _thresholdCubits = List.generate(3, (_) => ThresholdCubit());

    for (var i = 0; i < 3; i++) {
      if (_sensorIds[i].isNotEmpty) {
        _telemetryCubits[i].loadAndWatch(_sensorIds[i]);
        _thresholdCubits[i].load(_sensorIds[i]).then((_) {
          final s = _thresholdCubits[i].state;
          if (s is ThresholdLoaded) {
            _telemetryCubits[i].updateThreshold(s.min, s.max);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _telemetryCubits) {
      c.close();
    }
    for (final c in _thresholdCubits) {
      c.close();
    }
    super.dispose();
  }

  void _openThresholdSettings(BuildContext context) {
    final idx = _tabController.index;
    if (_sensorIds[idx].isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ThresholdSettingsWidget(
        sensorId: _sensorIds[idx],
        label: _labels[idx],
        unit: _units[idx],
        cubit: _thresholdCubits[idx],
        onSaved: (min, max) => _telemetryCubits[idx].updateThreshold(min, max),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: AppBar(
        backgroundColor: _darkBackground,
        foregroundColor: Colors.white,
        title: const Text('Телеметрія'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Налаштування порогів',
            onPressed: () => _openThresholdSettings(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF8A2BE2),
          tabs: const [
            Tab(text: 'Температура'),
            Tab(text: 'Вологість'),
            Tab(text: 'Тиск'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(
          3,
          (i) => _TelemetryTabView(
            cubit: _telemetryCubits[i],
            thresholdCubit: _thresholdCubits[i],
            unit: _units[i],
            label: _labels[i],
          ),
        ),
      ),
    );
  }
}

class _TelemetryTabView extends StatelessWidget {
  final TelemetryDataCubit cubit;
  final ThresholdCubit thresholdCubit;
  final String unit;
  final String label;

  const _TelemetryTabView({
    required this.cubit,
    required this.thresholdCubit,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TelemetryDataCubit, TelemetryDataState>(
      bloc: cubit,
      builder: (context, state) {
        if (state is TelemetryLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (state is TelemetryError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (state is TelemetryInitial) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Ідентифікатор сенсора "$label" не налаштовано у .env',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (state is TelemetryLoaded) {
          final currentValue = state.points.isNotEmpty
              ? (state.points.last['value'] as num).toDouble()
              : null;

          return BlocBuilder<ThresholdCubit, ThresholdState>(
            bloc: thresholdCubit,
            builder: (context, thresholdState) {
              final loaded = thresholdState is ThresholdLoaded
                  ? thresholdState
                  : null;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (currentValue != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${currentValue.toStringAsFixed(1)} $unit',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Expanded(
                      child: TelemetryChartWidget(
                        points: state.points,
                        unit: unit,
                        minThreshold: loaded?.min,
                        maxThreshold: loaded?.max,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
