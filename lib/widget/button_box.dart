import 'package:flutter/material.dart';

class ButtonBox extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;

  const ButtonBox({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF1E232C),
    this.textColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor,
          ),
        ),
      ),
    );
  }
}
