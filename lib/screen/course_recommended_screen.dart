import 'package:flutter/material.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/model/course.dart';
import 'package:prunners/model/location_util.dart';
import 'course_screen.dart';
import 'package:prunners/model/course_service.dart';

class CourseRecommendedScreen extends StatefulWidget {
  const CourseRecommendedScreen({super.key});

  @override
  State<CourseRecommendedScreen> createState() => _CourseRecommendedScreenState();
}

class _CourseRecommendedScreenState extends State<CourseRecommendedScreen> {
  final CourseService _courseService = CourseService();

  Future<List<Course>>? _nearbyCourse;
  Future<List<Course>>? _popularCourse;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    // 위치 먼저 가져오기
    final position = await LocationUtil.getCurrentPosition();
    if (position != null) {
      final lat = position.latitude;
      final lon = position.longitude;

      // 위치 기반 nearby course 요청
      _nearbyCourse = _courseService.getNearbyCourse(lat, lon);
    } else {
      _nearbyCourse = Future.value([]);  // 빈 리스트 fallback
    }

    // 인기 코스는 위치 필요 없음
    _popularCourse = _courseService.getPopularCourse();

    // 상태 업데이트
    setState(() {});
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
                  return const Center(child: Text('코스가 존재하지 않습니다.'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('코스가 존재하지 않습니다.'));
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
            const Text('인기 러닝 코스', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            FutureBuilder<List<Course>>(
              future: _popularCourse,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('코스가 존재하지 않습니다.'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('코스가 존재하지 않습니다.'));
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
                image: NetworkImage(course.imagePath),
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
