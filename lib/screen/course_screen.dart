import 'package:flutter/material.dart';
import 'package:prunners/screen/read_review_screen.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/outlined_button_box.dart';
import 'package:prunners/model/course.dart';

class CourseScreen extends StatelessWidget {
  final Course course;

  const CourseScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: CustomTopBar(title: course.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  course.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: Text('코스 정보', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Text('위치: ${course.location}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Text('거리: ${course.distance}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Wrap(
                  spacing: 8,
                  children: course.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 100),
              SizedBox(
                width: double.infinity,
                child: OutlinedButtonBox(
                  text: '리뷰 보러가기',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReadReviewScreen(courseId: course.course_id, coursetitle: course.title),
                      ),
                    );
                  },
                  fontSize: 15,
                ),
              )
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(
          currentIndex: 2,
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
