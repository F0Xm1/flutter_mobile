import 'package:flutter/material.dart';

class ReusableTextField extends StatelessWidget {
  final String hint;
  final bool obscure;
  final TextEditingController? controller;

  const ReusableTextField({
    required this.hint,
    super.key,
    this.obscure = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: hint,
          ),
        ),
      );
}
