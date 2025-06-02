import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test1/src/business/use_cases/login_user_use_case.dart';
import 'package:test1/src/cubit/auth/auth_cubit.dart';
import 'package:test1/src/screens/auth_page/login_form.dart';
import 'package:test1/src/screens/auth_page/login_listeners.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    const darkBackground = Color(0xFF1A1B2D);

    return BlocProvider<AuthCubit>(
      create: (context) {
        final cubit = AuthCubit(
          loginUserUseCase: context.read<LoginUserUseCase>(),
          prefs: context.read<SharedPreferences>(),
        );
        cubit.checkAutoLogin(context);
        return cubit;
      },
      child: const LoginListeners(
        child: Scaffold(
          backgroundColor: darkBackground,
          body: Stack(
            children: [
              _LoginBackground(),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: LoginForm(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    const darkBackground = Color(0xFF1A1B2D);
    const accentPurple = Color(0xFF8A2BE2);
    const lightPurple = Color(0xFFB19CD9);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [darkBackground, Color(0xFF25274D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: lightPurple.withOpacity(0.3),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -50,
            child: CircleAvatar(
              radius: 125,
              backgroundColor: accentPurple.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}
