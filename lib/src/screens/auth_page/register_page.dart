import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/core/app_colors.dart';
import 'package:test1/src/cubit/auth/auth_cubit.dart';
// ignore: unused_import
import 'package:test1/src/screens/auth_page/register_form.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgDeep,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.bgDeep, Color(0xFF1A0A00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: -80,
              right: -40,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.orange.withValues(alpha: 0.35),
                      AppColors.orange.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.orangeWarm.withValues(alpha: 0.25),
                      AppColors.orangeWarm.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            const SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: RegisterForm(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
