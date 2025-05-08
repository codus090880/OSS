import 'package:flutter/material.dart';

class AloneScreen extends StatefulWidget {
  const AloneScreen({super.key});

  @override
  State<AloneScreen> createState() => _AloneScreenState();
}

class _AloneScreenState extends State<AloneScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: const Center(
        child: Text(
            '혼자 뛸래요'
        )
      ),
    );
  }
}
