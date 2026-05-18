import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/core/app_colors.dart';
import 'package:test1/presentation/cubits/events_cubit.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late final EventsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = EventsCubit();
    _cubit.loadAndWatch();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EventsCubit>.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.bgDeep,
        appBar: AppBar(
          backgroundColor: AppColors.bgSurface,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: AppColors.orange.withValues(alpha: 0.3),
            ),
          ),
          title: const Text('Журнал подій'),
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.bgDeep, Color(0xFF140800)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: BlocBuilder<EventsCubit, EventsState>(
            builder: (context, state) {
              if (state is EventsLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.orange),
                );
              }
              if (state is EventsError) {
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
              if (state is EventsLoaded) {
                if (state.events.isEmpty) {
                  return const Center(
                    child: Text(
                      'Порогів ще не було перевищено',
                      style: TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => context.read<EventsCubit>().refresh(),
                  color: AppColors.orange,
                  backgroundColor: AppColors.bgElevated,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    itemCount: state.events.length,
                    itemBuilder: (context, index) =>
                        _EventCard(event: state.events[index]),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final sensorType = event['sensor_type'] as String;
    final value = (event['value'] as num).toDouble();
    final thresholdType = event['threshold_type'] as String;
    final thresholdValue = (event['threshold_value'] as num).toDouble();
    final raw = event['triggered_at'] as String?;
    final triggeredAt =
        raw != null ? DateTime.parse(raw).toLocal() : DateTime.now();

    final isMax = thresholdType == 'max';
    final accentColor = isMax ? Colors.redAccent : Colors.blueAccent;
    final bgColor = isMax
        ? Colors.red.withValues(alpha: 0.12)
        : Colors.blue.withValues(alpha: 0.10);
    final borderColor = isMax
        ? Colors.redAccent.withValues(alpha: 0.4)
        : Colors.blueAccent.withValues(alpha: 0.35);

    final unit = _unitFor(sensorType);
    final label = _labelFor(sensorType);
    final icon = _iconFor(sensorType);
    final thresholdText = isMax
        ? 'Перевищено макс. ${thresholdValue.toStringAsFixed(1)}$unit'
        : 'Нижче мін. ${thresholdValue.toStringAsFixed(1)}$unit';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '${value.toStringAsFixed(1)} $unit',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  thresholdText,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(triggeredAt),
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'щойно';
    if (diff.inMinutes < 60) return '${diff.inMinutes} хв тому';
    if (diff.inHours < 24) return '${diff.inHours} год тому';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}.${dt.month} $h:$m';
  }

  IconData _iconFor(String type) => switch (type) {
        'temperature' => Icons.thermostat,
        'humidity' => Icons.water_drop,
        _ => Icons.speed,
      };

  String _unitFor(String type) => switch (type) {
        'temperature' => '°C',
        'humidity' => '%',
        _ => 'hPa',
      };

  String _labelFor(String type) => switch (type) {
        'temperature' => 'Температура',
        'humidity' => 'Вологість',
        _ => 'Тиск',
      };
}
