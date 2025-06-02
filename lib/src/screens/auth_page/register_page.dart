import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/src/business/use_cases/register_user_use_case.dart';
import 'package:test1/src/cubit/register/register_cubit.dart';
import 'package:test1/src/screens/auth_page/register_form.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    const darkBackground = Color(0xFF1A1B2D);
    const accentPurple = Color(0xFF8A2BE2);
    const lightPurple = Color(0xFFB19CD9);

    return BlocProvider(
      create: (context) => RegisterCubit(
        registerUserUseCase: context.read<RegisterUserUseCase>(),
      ),
      child: BlocListener<RegisterCubit, RegisterState>(
        listener: (context, state) {
          if (state is RegisterSuccess) {
            Navigator.pushReplacementNamed(context, '/');
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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                top: -100,
                left: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: lightPurple.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -120,
                right: -50,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: accentPurple.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: RegisterForm(),
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
