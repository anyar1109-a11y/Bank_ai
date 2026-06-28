import 'package:flutter/material.dart';

class CustomTextField
    extends StatelessWidget {
  final String hint;

  final bool obscure;

  final TextEditingController
      controller;

  const CustomTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,

      obscureText: obscure,

      decoration: InputDecoration(
        hintText: hint,

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),
      ),
    );
  }
}