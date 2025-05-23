import 'package:flutter/material.dart';
import 'package:prunners/widget/rounded_shadow_box.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:dio/dio.dart';

class Badge {
  final String id;
  final String title;
  final bool isUnlocked;
  final IconData icon;

  const Badge({
    required this.id,
    required this.title,
    required this.isUnlocked,
    required this.icon,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      title: json['title'],
      isUnlocked: json['is_unlocked'],
      icon: _iconFromId(json['id']),
    );
  }
  static IconData _iconFromId(String id) {
    switch (id) {
      case 'first_run':
        return Icons.directions_run;
      case 'review_writer':
        return Icons.edit_note;
      case 'ten_runs':
        return Icons.directions_walk;
      default:
        return Icons.emoji_events;
    }
  }
}

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  late Future<List<Badge>> _badgeFuture;

  @override
  void initState() {
    super.initState();
    _badgeFuture = fetchBadges();
  }

  Future<List<Badge>> fetchBadges() async {
    final dio = Dio();
    final response = await dio.get('http://127.0.0.1:8000/badges/');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((e) => Badge.fromJson(e)).toList();
    } else {
      throw Exception('뱃지 데이터를 불러올 수 없습니다');
    }
  }

/*
  List<Badge> badgeList = [];

  void initState() {
    super.initState();
    badgeList = [
      Badge(id: 'first_run', title: '첫 러닝', icon: Icons.directions_run, isUnlocked: true),
      Badge(id: 'review_writer', title: '첫 후기', icon: Icons.edit_note, isUnlocked: false),
      Badge(id: 'ten_runs', title: '10회 러닝', icon: Icons.directions_walk, isUnlocked: false),
    ];
  }

 */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(title: '나의 뱃지'),
      ),
      body: FutureBuilder<List<Badge>>(
        future: _badgeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final badges = snapshot.data!;
          final unlocked = badges.where((b) => b.isUnlocked).length;
          final total = badges.length;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 15.0),
                  child: Text(
                    '뱃지 현황',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 20),
                RoundedShadowBox(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _BadgeState(badge_title: '발견한 뱃지', count: unlocked),
                      _BadgeState(badge_title: '미발견 뱃지', count: total - unlocked),
                      _BadgeState(badge_title: '전체 뱃지', count: total),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: badges.map((b) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(b.icon, size: 40, color: b.isUnlocked ? Colors.amber : Colors.grey),
                        const SizedBox(height: 5),
                        Text(
                          b.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: b.isUnlocked ? Colors.black : Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )).toList(),
                  ),
                ),
              ],
            ),
          );
        },
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