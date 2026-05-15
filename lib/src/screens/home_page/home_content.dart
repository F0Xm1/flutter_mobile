import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/presentation/cubits/dashboard_cubit.dart';
import 'package:test1/presentation/widgets/backend_status_widget.dart';
import 'package:test1/presentation/widgets/sensor_card.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (state is DashboardLoaded) {
          return _DashboardView(state: state);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _DashboardView extends StatelessWidget {
  final DashboardLoaded state;

  const _DashboardView({required this.state});

  DateTime? get _lastUpdated {
    final times = [
      state.temperature.lastUpdated,
      state.humidity.lastUpdated,
      state.pressure.lastUpdated,
    ].whereType<DateTime>().toList();
    if (times.isEmpty) return null;
    return times.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  String get _activeLocationName {
    final active = state.locations.where(
      (l) => l['id'] == state.activeLocationId,
    );
    return active.isNotEmpty ? active.first['name'] as String : '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (state.isFromCache)
          Container(
            width: double.infinity,
            color: Colors.amber.shade700,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.black87, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Офлайн — показуємо останні відомі дані',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BackendStatusWidget(lastUpdated: _lastUpdated),
                if (state.lastAlert != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      state.lastAlert!,
                      style:
                          const TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SensorCard(
                        label: 'Температура',
                        unit: '°C',
                        icon: Icons.thermostat,
                        data: state.temperature,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SensorCard(
                        label: 'Вологість',
                        unit: '%',
                        icon: Icons.water_drop,
                        data: state.humidity,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SensorCard(
                  label: 'Тиск',
                  unit: 'hPa',
                  icon: Icons.speed,
                  data: state.pressure,
                ),
                const SizedBox(height: 28),
                _NavButton(
                  icon: Icons.show_chart,
                  label: 'Телеметрія',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/telemetry',
                    arguments: {
                      'locationId': state.activeLocationId,
                      'locationName': _activeLocationName,
                    },
                  ),
                ),
                const SizedBox(height: 10),
                _NavButton(
                  icon: Icons.event_note,
                  label: 'Журнал подій',
                  onTap: () => Navigator.pushNamed(context, '/events'),
                ),
                const SizedBox(height: 10),
                _NavButton(
                  icon: Icons.sensors,
                  label: 'Сенсори',
                  onTap: () => Navigator.pushNamed(context, '/sensors'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accentPurple = Color(0xFF8A2BE2);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPurple,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
