import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/core/app_colors.dart';
import 'package:test1/src/cubit/auth/auth_cubit.dart';
// ignore: unused_import
import 'package:test1/src/widgets/reusable/reusable_text.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister(BuildContext context) {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final validationError = _validateRegister(
      email: email,
      name: name,
      password: password,
      confirmPassword: confirmPassword,
    );
    if (validationError != null) {
      setState(() => _localError = validationError);
      return;
    }

    setState(() => _localError = null);
    context.read<AuthCubit>().signUp(
          email,
          password,
          name: name,
        );
  }

  String? _validateRegister({
    required String email,
    required String name,
    required String password,
    required String confirmPassword,
  }) {
    if (email.isEmpty) {
      return 'Введіть email.';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Некоректний email.';
    }
    if (name.isEmpty) {
      return 'Введіть ім’я.';
    }
    if (RegExp(r'\d').hasMatch(name)) {
      return 'Ім’я не може містити цифри.';
    }
    if (password.isEmpty) {
      return 'Пароль не може бути порожнім.';
    }
    if (password.length < 6) {
      return 'Пароль має бути не менше 6 символів.';
    }
    if (password != confirmPassword) {
      return 'Паролі не співпадають.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 6),
        const Text(
          'Створіть новий обліковий запис',
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
              ReusableTextField(hint: 'Email', controller: _emailController),
              const SizedBox(height: 12),
              ReusableTextField(hint: "Ім'я", controller: _nameController),
              const SizedBox(height: 12),
              ReusableTextField(
                hint: 'Пароль',
                obscure: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 12),
              ReusableTextField(
                hint: 'Підтвердіть пароль',
                obscure: true,
                controller: _confirmPasswordController,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
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
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _onRegister(context),
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
                        'Зареєструватися',
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
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Вже маєте обліковий запис? ',
              style: TextStyle(color: Colors.white54),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Увійдіть',
                style: TextStyle(
                  color: AppColors.orangeWarm,
                  fontWeight: FontWeight.bold,
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
