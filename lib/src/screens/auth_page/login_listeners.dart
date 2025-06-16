import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test1/src/bloc/connection/connection_bloc.dart';
import 'package:test1/src/bloc/connection/connection_state.dart' as connection;
import 'package:test1/src/cubit/auth/auth_cubit.dart';

class LoginListeners extends StatelessWidget {
  final Widget child;

  const LoginListeners({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ConnectionBloc, connection.ConnectionState>(
          listener: (context, state) {
            if (state is connection.ConnectionDisconnected) {
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Відсутнє підключення'),
                  content: const Text(
                    'Інтернет зник! Деякі функції можуть бути недоступні.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
          },
        ),
        BlocListener<AuthCubit, AuthState>(
          listener: (context, state) async {
            if (state is AuthSuccess) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', true);

              if (context.mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacementNamed(context, '/home');
                });
              }
            }
          },
        ),
      ],
      child: child,
    );
  }
}
