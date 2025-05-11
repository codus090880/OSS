import 'package:flutter/material.dart';
import 'package:prunners/widget/rounded_shadow_box.dart';
import 'package:prunners/widget/bottom_bar.dart';

class Badge {
  final String id;
  final String title;
  final IconData icon;
  final bool isUnlocked;

  const Badge({
    required this.id,
    required this.title,
    required this.icon,
    required this.isUnlocked,
  });
}

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  List<Badge> badgeList = [];

  void initState() {
    super.initState();
    badgeList = [
      Badge(id: 'first_run', title: '첫 러닝', icon: Icons.directions_run, isUnlocked: true),
      Badge(id: 'review_writer', title: '첫 후기', icon: Icons.edit_note, isUnlocked: false),
      Badge(id: 'ten_runs', title: '10회 러닝', icon: Icons.directions_walk, isUnlocked: false),
    ];
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '나의 뱃지',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 25,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: const Text(
                '뱃지 현황',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 20),
            RoundedShadowBox(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _BadgeState(badge_title: '발견한 뱃지', count: 0),
                  _BadgeState(badge_title: '미발견 뱃지', count: 50),
                  _BadgeState(badge_title: '전체 뱃지', count: 50),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(
          currentIndex: 3,
          onTap: (index) {
            Navigator.pushReplacementNamed(
              context,
              ['/home', '/running', '/course', '/profile'][index],
            );
          },
        ),
      ),
    );
  }
}

class _BadgeState extends StatelessWidget {
  final String badge_title;
  final int count;

  const _BadgeState({
    required this.badge_title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          badge_title,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}