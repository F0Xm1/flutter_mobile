import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/core/app_colors.dart';
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
            child: CircularProgressIndicator(color: AppColors.orange),
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
    if (state.locations.isEmpty) {
      return _EmptyState(
        icon: Icons.location_off_outlined,
        title: 'Налаштуйте систему',
        subtitle: 'Додайте першу локацію, щоб почати збирати дані з сенсорів',
        buttonLabel: 'Налаштувати',
        onButtonTap: () => Navigator.pushNamedAndRemoveUntil(
          context,
          '/onboarding',
          (route) => false,
        ),
      );
    }

    if (state.sensorTypes.isEmpty) {
      return _EmptyState(
        icon: Icons.sensors_off_outlined,
        title: 'Немає сенсорів',
        subtitle: 'Додайте сенсори до локації, щоб бачити дані на дашборді',
        buttonLabel: 'Додати сенсори',
        onButtonTap: () => Navigator.pushNamed(context, '/sensors').then((_) {
          if (context.mounted) {
            context.read<DashboardCubit>().reload();
          }
        }),
      );
    }

    return Column(
      children: [
        if (state.isFromCache)
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.bgSurface,
              border: Border(
                left: BorderSide(color: AppColors.orange, width: 3),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Row(
              children: [
                Icon(Icons.wifi_off, color: AppColors.orange, size: 16),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Офлайн — показуємо останні відомі дані',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.orange,
            backgroundColor: AppColors.bgSurface,
            onRefresh: () => context.read<DashboardCubit>().reload(),
            child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BackendStatusWidget(lastUpdated: _lastUpdated),
                if (state.lastAlert != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      state.lastAlert!,
                      style: const TextStyle(
                        color: AppColors.amber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _SensorCards(state: state),
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
                  onTap: () =>
                      Navigator.pushNamed(context, '/sensors').then((_) {
                    if (context.mounted) {
                      context.read<DashboardCubit>().reload();
                    }
                  }),
                ),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }
}

class _SensorCards extends StatelessWidget {
  final DashboardLoaded state;

  const _SensorCards({required this.state});

  @override
  Widget build(BuildContext context) {
    final hasTemp = state.sensorTypes.contains('temperature');
    final hasHumidity = state.sensorTypes.contains('humidity');
    final hasPressure = state.sensorTypes.contains('pressure');

    return Column(
      children: [
        if (hasTemp && hasHumidity)
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
          )
        else if (hasTemp)
          SensorCard(
            label: 'Температура',
            unit: '°C',
            icon: Icons.thermostat,
            data: state.temperature,
          )
        else if (hasHumidity)
          SensorCard(
            label: 'Вологість',
            unit: '%',
            icon: Icons.water_drop,
            data: state.humidity,
          ),
        if (hasPressure) ...[
          if (hasTemp || hasHumidity) const SizedBox(height: 12),
          SensorCard(
            label: 'Тиск',
            unit: 'hPa',
            icon: Icons.speed,
            data: state.pressure,
          ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onButtonTap;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 72,
              color: AppColors.orange.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onButtonTap,
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
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
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bgSurface,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: AppColors.orange.withValues(alpha: 0.5),
            ),
          ),
          elevation: 0,
        ),
        icon: Icon(icon, color: AppColors.orange, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
