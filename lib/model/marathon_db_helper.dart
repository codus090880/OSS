import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../screen/home_screen.dart';

class MarathonDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('marathon365.sqlite3');
    return _database!;
  }

  static Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(path, version: 1);
  }

  static Future<List<MarathonEvent>> getEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('marathon_schedule');

    final dateFormat = DateFormat('M/d');
    final now = DateTime.now();

    return maps.map((map) {
      final rawDate = map['날짜'] as String;
      late DateTime parsedDate;

      try {
        final cleaned = rawDate.split('(').first.trim();
        final temp = dateFormat.parse(cleaned);
        parsedDate = DateTime(now.year, temp.month, temp.day);
      } catch (e) {
        debugPrint('⚠ 날짜 파싱 실패: $rawDate → $e');
        parsedDate = DateTime(1900); // 잘못된 날짜는 과거로 설정해 제외
      }

      return MarathonEvent(
        name: map['대회명'],
        date: parsedDate,
        course: map['코스'],
        url: map['관련링크'],
      );
    })
        .where((event) =>
    event.date.isAfter(now.subtract(Duration(days: 1))) && // 오늘 이후
        event.date.month == now.month &&                      // 이번 달
        event.date.year == now.year)                          // 올해
        .toList();
  }

}
