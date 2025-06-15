import 'package:flutter/material.dart';
import 'package:prunners/widget/top_bar.dart';

class LevelGuideScreen extends StatelessWidget {
  const LevelGuideScreen({super.key});

  Widget buildLevel({
    required IconData icon,
    required Color color,
    required String title,
    required List<String> guide,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 20, 45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...guide.map(
                (guideText) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $guideText',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.left,
              ),
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomTopBar(title: '레벨 가이드'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildLevel(
                        icon: Icons.leaderboard,
                        color: Color(0xFF854F4F), // Starter 색
                        title: 'Starter',
                        guide: [
                          '달리기를 아직 시작해본적 없어요.',
                          '1km 걷기+달리기부터 함께 연습해요.',
                        ],
                      ),
                      buildLevel(
                        icon: Icons.leaderboard,
                        color: Color(0xFF9F8357), // Beginner 색
                        title: 'Beginner',
                        guide: [
                          '3km를 천천히 걷거나 뛰며 완주할 수 있어요.',
                          '러닝이 아직 낯설고, 쉬면서 달려도 괜찮아요.',
                        ],
                      ),
                      buildLevel(
                        icon: Icons.leaderboard,
                        color: Color(0xFF3A7ACD), // Intermediate 색
                        title: 'Intermediate',
                        guide: [
                          '5km를 달릴 수 있어요.',
                          '주 1~2회 러닝 경험이 있어요.',
                        ],
                      ),
                      buildLevel(
                        icon: Icons.leaderboard,
                        color: Color(0xFF9A4DB2), // Advanced 색
                        title: 'Advanced',
                        guide: [
                          '10km 이상 달리기가 익숙해요.',
                          '일정한 속도로 러닝을 유지할 수 있어요.',
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
