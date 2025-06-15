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

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final position = await LocationUtil.getCurrentPosition();
    if (position != null) {
      final lat = position.latitude;
      final lon = position.longitude;

      _nearbyCourse = _courseService.getNearbyCourse(lat, lon);
    } else {
      _nearbyCourse = Future.value([]);
    }

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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('내 주변 러닝 코스', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Course>>(
                future: _nearbyCourse,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('코스가 존재하지 않습니다.'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('코스가 존재하지 않습니다.'));
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2열
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3 / 4, // 카드 비율 (너비:높이)
                    ),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final course = snapshot.data![index];
                      return CourseCard(course: course);
                    },
                  );
                },
              ),
            ),
          ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(course.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            course.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${course.distance.toStringAsFixed(1)}km',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
