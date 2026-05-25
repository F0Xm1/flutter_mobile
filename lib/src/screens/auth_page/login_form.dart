import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/core/app_colors.dart';
import 'package:test1/src/cubit/auth/auth_cubit.dart';
// ignore: unused_import
import 'package:test1/src/widgets/reusable/reusable_text.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin(BuildContext context) {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final validationError = _validateLogin(email, password);
    if (validationError != null) {
      setState(() => _localError = validationError);
      return;
    }

    setState(() => _localError = null);
    context.read<AuthCubit>().signIn(email, password);
  }

  String? _validateLogin(String email, String password) {
    if (email.isEmpty) {
      return 'Введіть email.';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Некоректний email.';
    }
    if (password.isEmpty) {
      return 'Пароль не може бути порожнім.';
    }
    return null;
  }

  Future<void> _onGoogleLogin(BuildContext context) async {
    setState(() => _localError = null);
    await context.read<AuthCubit>().signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Future.microtask(() {
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (Route<dynamic> route) => false,
              );
            }
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ласкаво просимо',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Увійдіть у свій обліковий запис',
            style: TextStyle(color: Colors.white54, fontSize: 15),
          ),
          const SizedBox(height: 36),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.orange.withValues(alpha: 0.25),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ReusableTextField(
                  hint: 'Email',
                  controller: _emailController,
                ),
                const SizedBox(height: 12),
                ReusableTextField(
                  hint: 'Пароль',
                  obscure: true,
                  controller: _passwordController,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _onLogin(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Увійти',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final message = _localError ??
                  switch (state) {
                    AuthError(:final message) => message,
                    _ => null,
                  };
              if (message != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const Row(
            children: [
              Expanded(
                child: Divider(color: Colors.white12, thickness: 1),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('або', style: TextStyle(color: Colors.white38)),
              ),
              Expanded(
                child: Divider(color: Colors.white12, thickness: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : () => _onGoogleLogin(context),
                  icon: const Icon(
                    Icons.g_mobiledata,
                    color: Colors.white70,
                  ),
                  label: const Text(
                    'Увійти через Google',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Немає облікового запису? ',
                style: TextStyle(color: Colors.white54),
              ),
              GestureDetector(
                onTap: () {
                  Future.microtask(() {
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/register',
                        (Route<dynamic> route) => true,
                      );
                    }
                  });
                },
                child: const Text(
                  'Зареєструватися',
                  style: TextStyle(
                    color: AppColors.orangeWarm,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
