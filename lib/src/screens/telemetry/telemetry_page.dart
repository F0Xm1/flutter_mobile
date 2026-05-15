import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/data/repositories/sensor_repository.dart';
import 'package:test1/src/cubit/telemetry/telemetry_data_cubit.dart';
import 'package:test1/src/cubit/threshold/threshold_cubit.dart';
import 'package:test1/src/widgets/telemetry_chart_widget.dart';
import 'package:test1/src/widgets/threshold_settings_widget.dart';

class TelemetryPage extends StatefulWidget {
  final String? locationId;

  const TelemetryPage({super.key, this.locationId});

  @override
  State<TelemetryPage> createState() => _TelemetryPageState();
}

class _TelemetryPageState extends State<TelemetryPage>
    with SingleTickerProviderStateMixin {
  static const _darkBackground = Color(0xFF1A1B2D);
  static const _typeOrder = {'temperature': 0, 'humidity': 1, 'pressure': 2};

  final _sensorRepo = SensorRepository();

  // null = still loading, empty = no sensors
  List<Map<String, dynamic>>? _sensors;
  TabController? _tabController;
  List<TelemetryDataCubit> _telemetryCubits = [];
  List<ThresholdCubit> _thresholdCubits = [];

  @override
  void initState() {
    super.initState();
    if (widget.locationId != null) {
      _loadSensors();
    } else {
      _sensors = [];
    }
  }

  Future<void> _loadSensors() async {
    try {
      final raw = await _sensorRepo.getSensorsByLocation(widget.locationId!);
      if (!mounted) return;

      final sensors = [...raw]
        ..sort((a, b) {
          final ai = _typeOrder[a['type']] ?? 99;
          final bi = _typeOrder[b['type']] ?? 99;
          return ai.compareTo(bi);
        });

      final n = sensors.length;

      final telemetryCubits = sensors
          .map(
            (s) => TelemetryDataCubit(
              label: _labelFor(s['type'] as String),
              unit: s['unit'] as String,
              sensorType: s['type'] as String,
            ),
          )
          .toList();

      final thresholdCubits = List.generate(n, (_) => ThresholdCubit());

      for (var i = 0; i < n; i++) {
        final sensorId = sensors[i]['id'] as String;
        telemetryCubits[i].loadAndWatch(sensorId);
        thresholdCubits[i].load(sensorId).then((_) {
          if (!mounted) return;
          final s = thresholdCubits[i].state;
          if (s is ThresholdLoaded) {
            telemetryCubits[i].updateThreshold(s.min, s.max);
          }
        });
      }

      setState(() {
        _sensors = sensors;
        _tabController = TabController(length: n, vsync: this);
        _telemetryCubits = telemetryCubits;
        _thresholdCubits = thresholdCubits;
      });
    } catch (error, stackTrace) {
      log(
        'Failed to load sensors for telemetry page',
        name: 'TelemetryPage',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() => _sensors = []);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    for (final c in _telemetryCubits) {
      c.close();
    }
    for (final c in _thresholdCubits) {
      c.close();
    }
    super.dispose();
  }

  void _openThresholdSettings(BuildContext context) {
    final sensors = _sensors;
    final tabController = _tabController;
    if (sensors == null || tabController == null || sensors.isEmpty) return;

    final idx = tabController.index;
    if (idx >= sensors.length) return;

    final sensor = sensors[idx];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ThresholdSettingsWidget(
        sensorId: sensor['id'] as String,
        label: _labelFor(sensor['type'] as String),
        unit: sensor['unit'] as String,
        cubit: _thresholdCubits[idx],
        onSaved: (min, max) => _telemetryCubits[idx].updateThreshold(min, max),
      ),
    );
  }

  String _labelFor(String type) => switch (type) {
        'temperature' => 'Температура',
        'humidity' => 'Вологість',
        _ => 'Тиск',
      };

  @override
  Widget build(BuildContext context) {
    final sensors = _sensors;

    if (sensors == null) {
      return Scaffold(
        backgroundColor: _darkBackground,
        appBar: AppBar(
          backgroundColor: _darkBackground,
          foregroundColor: Colors.white,
          title: const Text('Телеметрія'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (sensors.isEmpty) {
      return Scaffold(
        backgroundColor: _darkBackground,
        appBar: AppBar(
          backgroundColor: _darkBackground,
          foregroundColor: Colors.white,
          title: const Text('Телеметрія'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              widget.locationId == null
                  ? 'Локацію не вибрано'
                  : 'У цій локації немає сенсорів',
              style: const TextStyle(color: Colors.white54, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

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
          tabs: sensors
              .map((s) => Tab(text: _labelFor(s['type'] as String)))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(
          sensors.length,
          (i) => _TelemetryTabView(
            cubit: _telemetryCubits[i],
            thresholdCubit: _thresholdCubits[i],
            unit: sensors[i]['unit'] as String,
            label: _labelFor(sensors[i]['type'] as String),
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
        if (state is TelemetryLoading || state is TelemetryInitial) {
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
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                ),
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
              final loaded =
                  thresholdState is ThresholdLoaded ? thresholdState : null;

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
