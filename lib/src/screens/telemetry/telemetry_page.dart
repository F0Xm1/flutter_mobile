import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:test1/src/cubit/telemetry/telemetry_data_cubit.dart';
import 'package:test1/src/widgets/telemetry_chart_widget.dart';

class TelemetryPage extends StatefulWidget {
  const TelemetryPage({super.key});

  @override
  State<TelemetryPage> createState() => _TelemetryPageState();
}

class _TelemetryPageState extends State<TelemetryPage> {
  static const _darkBackground = Color(0xFF1A1B2D);

  late final TelemetryDataCubit _temperatureCubit;
  late final TelemetryDataCubit _humidityCubit;
  late final TelemetryDataCubit _pressureCubit;

  @override
  void initState() {
    super.initState();
    _temperatureCubit = TelemetryDataCubit();
    _humidityCubit = TelemetryDataCubit();
    _pressureCubit = TelemetryDataCubit();

    final tempId = dotenv.env['SENSOR_ID_TEMPERATURE'] ?? '';
    final humId = dotenv.env['SENSOR_ID_HUMIDITY'] ?? '';
    final pressId = dotenv.env['SENSOR_ID_PRESSURE'] ?? '';

    if (tempId.isNotEmpty) _temperatureCubit.loadAndWatch(tempId);
    if (humId.isNotEmpty) _humidityCubit.loadAndWatch(humId);
    if (pressId.isNotEmpty) _pressureCubit.loadAndWatch(pressId);
  }

  @override
  void dispose() {
    _temperatureCubit.close();
    _humidityCubit.close();
    _pressureCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _darkBackground,
        appBar: AppBar(
          backgroundColor: _darkBackground,
          foregroundColor: Colors.white,
          title: const Text('Телеметрія'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Color(0xFF8A2BE2),
            tabs: [
              Tab(text: 'Температура'),
              Tab(text: 'Вологість'),
              Tab(text: 'Тиск'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TelemetryTabView(
              cubit: _temperatureCubit,
              unit: '°C',
              label: 'Температура',
            ),
            _TelemetryTabView(
              cubit: _humidityCubit,
              unit: '%',
              label: 'Вологість',
            ),
            _TelemetryTabView(
              cubit: _pressureCubit,
              unit: 'hPa',
              label: 'Тиск',
            ),
          ],
        ),
      ),
    );
  }
}

class _TelemetryTabView extends StatelessWidget {
  final TelemetryDataCubit cubit;
  final String unit;
  final String label;

  const _TelemetryTabView({
    required this.cubit,
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
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
