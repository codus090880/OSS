import 'package:dio/dio.dart';
import 'package:prunners/model/course.dart';

class CourseService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:8000',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<List<Course>> getNearbyCourse() async {
    final response = await _dio.get('/courses/nearby');
    final List<dynamic> data = response.data;
    return data.map((e) => Course.fromJson(e)).toList();
  }

  Future<List<Course>> getPopularCourse() async {
    final response = await _dio.get('/courses/popular');
    final List<dynamic> data = response.data;
    return data.map((e) => Course.fromJson(e)).toList();
  }
}