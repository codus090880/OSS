import 'package:flutter/material.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/top_bar.dart';

class CourseRecommendedScreen extends StatefulWidget {
  const CourseRecommendedScreen({super.key});

  @override
  State<CourseRecommendedScreen> createState() => _CourseRecommendedScreenState();
}

class _CourseRecommendedScreenState extends State<CourseRecommendedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomTopBar(title: '코스 추천'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('내 주변 러닝 코스', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CourseCard(title: '러닝 코스 1', distance: '3.5 km', imagePath: 'assets/111.png'),
                CourseCard(title: '러닝 코스 2', distance: '3.5 km', imagePath: 'assets/111.png'),
              ],
            ),
            const SizedBox(height: 50),
            const Text('이번주 인기 러닝 코스', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CourseCard(title: '러닝 코스 3', distance: '5 km', imagePath: 'assets/111.png'),
                CourseCard(title: '러닝 코스 4', distance: '5 km', imagePath: 'assets/111.png'),
                CourseCard(title: '러닝 코스 5', distance: '5 km', imagePath: 'assets/111.png'),
              ],
            ),
          ],
        )
      ),
      bottomNavigationBar: SafeArea(
      top: false,
      child: BottomNavBar(
        currentIndex: 2, // 코스 탭 인덱스
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

class CourseCard extends StatelessWidget {
  final String title;
  final String distance;
  final String imagePath;

  const CourseCard({
    super.key,
    required this.title,
    required this.distance,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/course_detail');
      },
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text(distance, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

