import 'package:flutter/material.dart';
import 'package:prunners/widget/bottom_bar.dart';

class CourseRecommendScreen extends StatefulWidget {
  const CourseRecommendScreen({super.key});

  @override
  State<CourseRecommendScreen> createState() => _CourseRecommendScreen();
}

class _CourseRecommendScreen extends State<CourseRecommendScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text(
            '코스 추천'
        ),
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
