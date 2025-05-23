import 'package:flutter/material.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/model/course.dart';
import 'course_screen.dart';
import 'package:prunners/model/course_service.dart';

class CourseRecommendedScreen extends StatefulWidget {
  const CourseRecommendedScreen({super.key});

  @override
  State<CourseRecommendedScreen> createState() => _CourseRecommendedScreenState();
}

class _CourseRecommendedScreenState extends State<CourseRecommendedScreen> {
  // MockData
  /*
  final List<Course> nearbyCourses = [
    Course(course_id: 1, title: '러닝 코스 1', distance: '3.5 km', location: '서울',
      imagePath: 'assets/111.png', tags: ['#한강', '#초보자용', '#야경좋음'],),
    Course(course_id: 2, title: '러닝 코스 2', distance: '3.5 km', location: '서울',
      imagePath: 'assets/111.png', tags: ['#한강', '#초보자용', '#야경좋음'],),
    Course(course_id: 3, title: '러닝 코스 3', distance: '5 km', location: '서울',
      imagePath: 'assets/111.png', tags: ['#한강', '#초보자용', '#야경좋음'],),
  ];

  final List<Course> popularCourses = [
    Course(course_id: 6, title: '러닝 코스 4', distance: '5 km', location: '서울',
      imagePath: 'assets/111.png', tags: ['#한강', '#초보자용', '#야경좋음'],),
    Course(course_id: 7, title: '러닝 코스 5', distance: '5 km', location: '서울',
      imagePath: 'assets/111.png', tags: ['#한강', '#초보자용', '#야경좋음'],),
    Course(course_id: 8, title: '러닝 코스 6', distance: '5 km', location: '서울',
      imagePath: 'assets/111.png', tags: ['#한강', '#초보자용', '#야경좋음'],),
    Course(course_id: 9, title: '러닝 코스 7', distance: '5 km', location: '서울',
      imagePath: 'assets/111.png', tags: ['#한강', '#초보자용', '#야경좋음'],),
    Course(course_id: 10, title: '러닝 코스 8', distance: '5 km', location: '서울',
      imagePath: 'assets/111.png', tags: ['#한강', '#초보자용', '#야경좋음'],),
  ];
  */

  final CourseService _courseService = CourseService();

  late Future<List<Course>> _nearbyCourse;
  late Future<List<Course>> _popularCourse;

  @override
  void initState() {
    super.initState();
    _nearbyCourse = _courseService.getNearbyCourse();
    _popularCourse = _courseService.getPopularCourse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '코스 추천',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 25,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('내 주변 러닝 코스', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            FutureBuilder<List<Course>>(
              future: _nearbyCourse,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: snapshot.data!
                        .map((course) => Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: CourseCard(course: course),
                    )).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 50),
            const Text('이번주 인기 러닝 코스', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            FutureBuilder<List<Course>>(
              future: _popularCourse,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: snapshot.data!
                        .map((course) => Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: CourseCard(course: course),
                    ))
                        .toList(),
                  ),
                );
              },
            ),
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

class CourseCard extends StatelessWidget {
  final Course course;

  const CourseCard({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseScreen(course: course),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: AssetImage(course.imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(course.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text(course.distance, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
