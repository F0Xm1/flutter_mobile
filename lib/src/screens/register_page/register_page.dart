import 'package:flutter/material.dart';
import 'package:test1/src/widgets/reusable_button/reusable_button.dart';
import 'package:test1/src/widgets/reusable_text_field/reusable_text.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade300,
            Colors.orange.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 8,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Реєстрація',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const ReusableTextField(hint: 'Email'),
                  const SizedBox(height: 12),
                  const ReusableTextField(hint: 'Пароль', obscure: true),
                  const SizedBox(height: 12),
                  const ReusableTextField(
                    hint: 'Підтвердіть пароль',
                    obscure: true,),
                  const SizedBox(height: 16),
                  ReusableButton(
                    text: 'Зареєструватись',
                    onPressed: () => Navigator.pushNamed(context, '/station'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
