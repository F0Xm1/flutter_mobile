import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/src/cubit/auth/auth_cubit.dart';
import 'package:test1/src/widgets/reusable/reusable_text.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _onLogin(BuildContext context) {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    context.read<AuthCubit>().login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    const accentPurple = Color(0xFF8A2BE2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Ласкаво просимо назад',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Увійдіть у свій обліковий запис',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ReusableTextField(
                hint: 'Email',
                controller: _emailController,
              ),
              const SizedBox(height: 16),
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
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _onLogin(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Увійти',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthFailure) {
              return Column(
                children: [
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        TextButton(
          onPressed: () {
            // Відновлення паролю
          },
          child: const Text(
            'Забули пароль?',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 60, height: 1, color: Colors.white30),
            const SizedBox(width: 8),
            const Text('або', style: TextStyle(color: Colors.white54)),
            const SizedBox(width: 8),
            Container(width: 60, height: 1, color: Colors.white30),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Немає облікового запису? ',
              style: TextStyle(color: Colors.white70),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text(
                'Зареєструватися',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
