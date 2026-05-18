import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/core/app_colors.dart';
import 'package:test1/data/repositories/sensor_repository.dart';
import 'package:test1/src/bloc/connection/connection_bloc.dart';
import 'package:test1/src/bloc/connection/connection_state.dart' as conn;
import 'package:test1/src/cubit/telemetry/telemetry_data_cubit.dart';
import 'package:test1/src/cubit/threshold/threshold_cubit.dart';
import 'package:test1/src/services/export_service.dart';
import 'package:test1/src/widgets/telemetry_chart_widget.dart';
import 'package:test1/src/widgets/threshold_settings_widget.dart';

class TelemetryPage extends StatefulWidget {
  final String? locationId;
  final String locationName;

  const TelemetryPage({
    super.key,
    this.locationId,
    this.locationName = '',
  });

  @override
  State<TelemetryPage> createState() => _TelemetryPageState();
}

class _TelemetryPageState extends State<TelemetryPage>
    with SingleTickerProviderStateMixin {
  static const _typeOrder = {'temperature': 0, 'humidity': 1, 'pressure': 2};

  final _sensorRepo = SensorRepository();

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
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ThresholdSettingsWidget(
        sensorId: sensor['id'] as String,
        label: _labelFor(sensor['type'] as String),
        unit: sensor['unit'] as String,
        cubit: _thresholdCubits[idx],
        onSaved: (min, max) => _telemetryCubits[idx].updateThreshold(min, max),
      ),
    );
  }

  void _openExportSheet(BuildContext context) {
    final sensors = _sensors;
    if (sensors == null || sensors.isEmpty) return;

    final connState = context.read<ConnectionBloc>().state;
    if (connState is conn.ConnectionDisconnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Немає підключення до мережі'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ExportBottomSheet(
        sensors: sensors,
        locationName: widget.locationName,
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
        backgroundColor: AppColors.bgDeep,
        appBar: _buildAppBar(null),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
      );
    }

    if (sensors.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bgDeep,
        appBar: _buildAppBar(null),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              widget.locationId == null
                  ? 'Локацію не вибрано'
                  : 'У цій локації немає сенсорів',
              style: const TextStyle(color: Colors.white38, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: _buildAppBar(sensors),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.bgDeep, Color(0xFF140800)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
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
      ),
    );
  }

  AppBar _buildAppBar(List<Map<String, dynamic>>? sensors) {
    return AppBar(
      backgroundColor: AppColors.bgSurface,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text('Телеметрія'),
      actions: sensors != null
          ? [
              IconButton(
                icon: const Icon(
                  Icons.file_download_outlined,
                  color: AppColors.orangeWarm,
                ),
                tooltip: 'Експорт CSV',
                onPressed: () => _openExportSheet(context),
              ),
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.white54),
                tooltip: 'Налаштування порогів',
                onPressed: () => _openThresholdSettings(context),
              ),
            ]
          : null,
      bottom: sensors != null
          ? TabBar(
              controller: _tabController,
              labelColor: AppColors.orange,
              unselectedLabelColor: Colors.white38,
              indicatorColor: AppColors.orange,
              indicatorWeight: 3,
              tabs: sensors
                  .map((s) => Tab(text: _labelFor(s['type'] as String)))
                  .toList(),
            )
          : PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: AppColors.orange.withValues(alpha: 0.3),
              ),
            ),
    );
  }
}

class _ExportBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> sensors;
  final String locationName;

  const _ExportBottomSheet({
    required this.sensors,
    required this.locationName,
  });

  @override
  State<_ExportBottomSheet> createState() => _ExportBottomSheetState();
}

class _ExportBottomSheetState extends State<_ExportBottomSheet> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();
  bool _loading = false;

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.orange,
            surface: AppColors.bgElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_from.isAfter(_to)) _to = _from;
      } else {
        _to = picked;
        if (_to.isBefore(_from)) _from = _to;
      }
    });
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';

  Future<void> _export() async {
    setState(() => _loading = true);
    try {
      await ExportService().exportToCsv(
        widget.locationName,
        widget.sensors,
        _from,
        DateTime(_to.year, _to.month, _to.day, 23, 59, 59),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка експорту: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        20,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Експорт телеметрії',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Оберіть діапазон дат для CSV-файлу',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'Від',
                  date: _fmt(_from),
                  enabled: !_loading,
                  onTap: () => _pickDate(isFrom: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateButton(
                  label: 'До',
                  date: _fmt(_to),
                  enabled: !_loading,
                  onTap: () => _pickDate(isFrom: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: _loading ? null : _export,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Експортувати',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String date;
  final bool enabled;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(
          color: enabled
              ? AppColors.orange.withValues(alpha: 0.5)
              : AppColors.border,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: enabled ? onTap : null,
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.orangeWarm,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(date, style: const TextStyle(fontSize: 14)),
        ],
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
            child: CircularProgressIndicator(color: AppColors.orange),
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
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
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
