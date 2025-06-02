import 'package:flutter/material.dart';

class MatchingFailedScreen extends StatelessWidget {
  const MatchingFailedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                  Icons.sentiment_dissatisfied, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              const Text(
                '주변에 러닝 메이트가 없습니다',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                '잠시 후 다시 시도해보세요!',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/running');
                },
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}