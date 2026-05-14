import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/src/bloc/connection/connection_bloc.dart';
import 'package:test1/src/bloc/connection/connection_state.dart' as connection;
import 'package:test1/src/cubit/station/connection_cubit.dart';
import 'package:test1/src/screens/home_page/home_content.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const darkBackground = Color(0xFF1A1B2D);
    const accentPurple = Color(0xFF8A2BE2);
    const lightPurple = Color(0xFFB19CD9);

    return BlocProvider(
      create: (_) => ConnectorCubit(),
      child: BlocListener<ConnectionBloc, connection.ConnectionState>(
        listener: (context, state) {
          if (state is connection.ConnectionDisconnected) {
            context.read<ConnectorCubit>().disconnect();

            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                title: const Text('Відсутнє підключення'),
                content: const Text(
                  'Інтернет зник! Деякі функції можуть бути недоступні.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: darkBackground,
          body: Stack(
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
              const SafeArea(child: HomeContent()),
            ],
          ),
        ),
      ),
    );
  }
}
