import 'package:flutter/material.dart';
import 'package:test1/src/widgets/reusable_button/reusable_button.dart';
import 'package:test1/src/widgets/reusable_text_field/reusable_text.dart';


class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
                    'Логін',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const ReusableTextField(hint: 'Email'),
                  const SizedBox(height: 12),
                  const ReusableTextField(hint: 'Пароль', obscure: true),
                  const SizedBox(height: 16),
                  ReusableButton(
                    text: 'Увійти',
                    onPressed: () => Navigator.pushNamed(context, '/home'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    child: const Text(
                      'Реєстрація',
                      style: TextStyle(fontSize: 16, color: Colors.teal),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/register'),
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
