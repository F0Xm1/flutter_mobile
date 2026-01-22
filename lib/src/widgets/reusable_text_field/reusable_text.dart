import 'package:flutter/material.dart';

class ReusableTextField extends StatelessWidget {
  final String hint;
  final bool obscure;

  const ReusableTextField({
    required this.hint,
    this.obscure = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: hint,
      ),
    ),
  );
}
