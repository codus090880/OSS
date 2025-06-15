import 'package:flutter/material.dart';

class RoundedShadowBox extends StatelessWidget {
  final double? height;
  final double? width;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const RoundedShadowBox({
    Key? key,
    this.height,
    this.width,
    this.padding = const EdgeInsets.fromLTRB(20, 7, 20, 7),
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      padding: padding,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: [],
      ),
      child: child,
    );
  }
}
