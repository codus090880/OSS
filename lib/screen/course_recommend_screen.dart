import 'package:flutter/material.dart';
import 'package:prunners/widget/bottom_bar.dart';

class CourseRecommendScreenf extends StatefulWidget {
  const CourseRecommendScreenf({super.key});

  @override
  State<CourseRecommendScreenf> createState() => _CourseRecommendScreen();
}

class _CourseRecommendScreen extends State<CourseRecommendScreenf> {
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
