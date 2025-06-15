import 'dart:ffi';

class Course {
  final int course_id;
  final String title;
  final double distance;
  final String imagePath;
  final String location;
  final List<String> tags;

  Course({
    required this.course_id,
    required this.title,
    required this.distance,
    required this.location,
    required this.imagePath,
    required this.tags,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      course_id: json['course_id'],
      title: json['title'],
      distance: (json['distance'] as num).toDouble(),
      location: json['location'],
      imagePath: json['image_url'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}