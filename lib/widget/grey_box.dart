import 'package:flutter/material.dart';

class GreyBox extends StatelessWidget {
  final Widget child;

  const GreyBox({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Color(0xFFF7F8F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE8ECF4)),
        ),
      child: child,
    );
  }
}
