// lib/model/push.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

const String WEATHER_API_URL = 'https://api.openweathermap.org/data/2.5/weather';
const String AIR_POLLUTION_API_URL = 'https://api.openweathermap.org/data/2.5/air_pollution';

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(settings);

    // 알림 권한 요청 (Android 13 이상 필요)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  static Future<void> initializeBackground() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(settings);
  }

  static Future<void> scheduleDailyFixed({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    // 현재 로컬 시각(Asia/Seoul) 구하기
    final now = tz.TZDateTime.now(tz.local);

    // 오늘(hour:minute)에 해당하는 TZDateTime 생성
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // 이미 지났으면 내일 같은 시각으로 설정
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_fixed_channel',
      '매일 아침 알림',
      channelDescription: '매일 오전 7시에 상쾌한 아침 메시지',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> fetchWeatherAndNotify(String apiKey) async {
    try {
      // 위치 권한 및 현재 위치 획득
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          return;
        }
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      double lat = position.latitude;
      double lon = position.longitude;

      // 날씨 정보 요청
      final dio = Dio();
      final weatherResp = await dio.get(
        WEATHER_API_URL,
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'appid': apiKey,
          'lang': 'kr',
          'units': 'metric',
        },
      );
      final pollutionResp = await dio.get(
        AIR_POLLUTION_API_URL,
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'appid': apiKey,
        },
      );
      final weather = weatherResp.data;
      final air = pollutionResp.data;
      final description = weather['weather'][0]['description'];
      final temperature = weather['main']['temp'];
      final pm10 = air['list'][0]['components']['pm10'];

      // 조건 검사: pm10 <= 800 && 맑음 (description == 'Clear' 예시)
      if (pm10 <= 80 && description.contains('맑음')) {
        const androidDetails = AndroidNotificationDetails(
          'weather_dynamic_channel',
          '날씨 기반 알림',
          channelDescription: '날씨와 미세먼지 정보 기반 알림',
          importance: Importance.high,
          priority: Priority.high,
        );
        const iosDetails = DarwinNotificationDetails();
        const notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        final title = '상쾌한 하루!';
        final body =
            '지금은 ${temperature.toStringAsFixed(1)}℃, 날씨: $description,\n미세먼지(PM10): ${pm10.toStringAsFixed(1)} µg/m³\n러닝하기 좋은 날씨예요!';
        await _plugin.show(999, title, body, notificationDetails);
      }
    } catch (e) {
      print('[ERROR] fetchWeatherAndNotify 실패: $e');
    }
  }
}
