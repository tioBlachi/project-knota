import 'package:flutter/material.dart';

/// A reusable widget to display a label with a red asterisk.
class RequiredLabel extends StatelessWidget {
  final String label;
  final String asterisk; // You can pass '*' or customize it

  const RequiredLabel({
    super.key, 
    required this.label, 
    this.asterisk = ' *',
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(
            text: asterisk,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
