import 'package:flutter/material.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/outlined_button_box.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<CourseScreen> createState() => _CourseScreen();
}

class _CourseScreen extends State<CourseScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(title: '러닝 코스 1'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/111.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: const Text('코스 정보', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: const Text('출발지: 충무로역 1번 출구', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: const Text('거리: 5.5km', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 165),
            SizedBox(
                width: double.infinity,
                child: OutlinedButtonBox(
                  text: '리뷰 보러가기',
                  onPressed: () {
                    Navigator.pushNamed(context, '/read');
                  },
                  fontSize: 15,
                )
            )
          ],
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