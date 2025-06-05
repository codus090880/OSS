import 'package:dio/dio.dart';
import 'package:prunners/model/course.dart';
import 'package:prunners/model/auth_service.dart';

class CourseService {
  final Dio _dio = AuthService.dio;

  Future<List<Course>> getNearbyCourse(double lat, double lon) async {
    try {
      final response = await _dio.get(
        '/courses/nearby',
        queryParameters: {
          'lat': lat.toString(),
          'lon': lon.toString(),
        },
      );

      print('[NearbyCourse] Response: ${response.data}');

      final List<dynamic> data = response.data;
      return data.map((e) => Course.fromJson(e)).toList();
    } catch (e) {
      print('nearby course 가져오기 에러: $e');
      return [];
    }
  }

  // popularCourse 도 동일
  Future<List<Course>> getPopularCourse() async {
    try {
      final response = await _dio.get('/courses/popular');
      print('[PopularCourse] Response: ${response.data}');

      final List<dynamic> data = response.data;
      return data.map((e) => Course.fromJson(e)).toList();
    } catch (e) {
      print('popular courses 가져오기 에러: $e');
      return [];
    }
  }
}