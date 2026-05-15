import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/src/bloc/connection/connection_bloc.dart';
import 'package:test1/src/bloc/connection/connection_state.dart' as connection;

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    const accentPurple = Color(0xFF8A2BE2);
    const lightPurple = Color(0xFFB19CD9);

    final isOnline =
        context.watch<ConnectionBloc>().state is connection.ConnectionConnected;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 30, horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.sensors, size: 40, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Smart Telemetry',
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
          child: Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentPurple.withValues(alpha: 0.4),
                    accentPurple.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  isOnline ? Icons.wifi : Icons.wifi_off,
                  size: 72,
                  color: isOnline ? Colors.white : Colors.white30,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isOnline
                      ? () => Navigator.pushNamed(context, '/telemetry')
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOnline ? accentPurple : Colors.white10,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.show_chart, color: Colors.white),
                  label: const Text(
                    'Телеметрія',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isOnline
                    ? 'Є підключення до мережі'
                    : 'Немає підключення до мережі',
                style: TextStyle(
                  color: isOnline ? lightPurple : Colors.white30,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
