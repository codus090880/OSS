import 'package:flutter/material.dart';

class OutlinedButtonBox extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color borderColor;
  final Color textColor;
  final double height;
  final double borderWidth;
  final double fontSize;

  const OutlinedButtonBox({
    Key? key,
    required this.text,
    required this.onPressed,
    this.borderColor = const Color(0xFF1E232C),
    this.textColor = const Color(0xFF1E232C),
    this.borderWidth = 1.0,
    this.height = 56,
    this.fontSize = 15,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor, width: borderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
