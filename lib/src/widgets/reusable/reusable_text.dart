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
  Widget build(BuildContext context) => TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: hint),
      );
}
