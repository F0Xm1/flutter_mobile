import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/src/cubit/register/register_cubit.dart';
import 'package:test1/src/widgets/reusable/reusable_text.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _onRegister(BuildContext context) {
    context.read<RegisterCubit>().register(
          email: _emailController.text.trim(),
          name: _nameController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    const accentPurple = Color(0xFF8A2BE2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Реєстрація',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Створіть новий обліковий запис',
          style: TextStyle(color: Colors.grey, fontSize: 16),
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
                hint: 'Ім’я',
                controller: _nameController,
              ),
              const SizedBox(height: 16),
              ReusableTextField(
                hint: 'Пароль',
                obscure: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 16),
              ReusableTextField(
                hint: 'Підтвердіть пароль',
                obscure: true,
                controller: _confirmPasswordController,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        BlocBuilder<RegisterCubit, RegisterState>(
          builder: (context, state) {
            if (state is RegisterFailure) {
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
        BlocBuilder<RegisterCubit, RegisterState>(
          builder: (context, state) {
            final isLoading = state is RegisterLoading;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _onRegister(context),
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
                        'Зареєструватися',
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Вже маєте обліковий запис? ',
              style: TextStyle(color: Colors.white70),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Увійдіть',
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
