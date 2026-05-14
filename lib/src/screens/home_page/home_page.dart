import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/src/bloc/connection/connection_bloc.dart';
import 'package:test1/src/bloc/connection/connection_state.dart' as connection;
import 'package:test1/src/cubit/auth/auth_cubit.dart';
import 'package:test1/src/screens/home_page/home_content.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthCubit>().signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBackground = Color(0xFF1A1B2D);

    return BlocListener<ConnectionBloc, connection.ConnectionState>(
      listener: (context, state) {
        if (state is connection.ConnectionDisconnected) {
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
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: darkBackground,
          foregroundColor: Colors.white,
          title: const Text('Чіпідізєль'),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              tooltip: 'Вийти',
              onPressed: () => _logout(context),
            ),
          ],
        ),
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
            const SafeArea(child: HomeContent()),
          ],
        ),
      ),
    );
  }
}
