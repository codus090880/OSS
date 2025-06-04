import 'package:dio/dio.dart';
import 'package:prunners/model/course.dart';

class CourseService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:8000',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<List<Course>> getNearbyCourse(double lat, double lon) async {
    try {
      final response = await _dio.get(
        '/courses/nearby',
        queryParameters: {
          'lat': lat,
          'lon': lon,
        },
      );

      final List<dynamic> data = response.data;
      return data.map((e) => Course.fromJson(e)).toList();
    } catch (e) {
      print('nearby course 가져오기 에러: $e');
      return [];
    }
  }

  Future<List<Course>> getPopularCourse() async {
    try {
      final response = await _dio.get('/courses/popular');
      final List<dynamic> data = response.data;
      return data.map((e) => Course.fromJson(e)).toList();
    } catch (e) {
      print('popular courses 가져오기 에러: $e');
      return [];
    }
  }
}