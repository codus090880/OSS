import 'package:flutter/material.dart';

class TogetherScreen extends StatefulWidget {
  const TogetherScreen({super.key});

  @override
  State<TogetherScreen> createState() => _TogetherScreenState();
}

class _TogetherScreenState extends State<TogetherScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: const Center(
        child: Text(
          '같이 뛸래요'
        ),
      ),
    );
  }
}
