import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
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
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      print('[ERROR] 위치 서비스 비활성화');
      return;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        print('[ERROR] 위치 권한 거부');
        return;
      }
    }
  }

  static Future<void> initializeBackground() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(initSettings);
  }

  static Future<void> showNotification({required String title, required String body, int id = 0}) async {
    const androidDetails = AndroidNotificationDetails(
      'weather_channel', '날씨 알림',
      channelDescription: '매일 아침 러닝 가능 여부 알림',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, notificationDetails);
  }

  static Future<void> scheduleOneTimeNotificationAt1240() async {
    // 1) 채널 및 세부 설정
    const androidDetails = AndroidNotificationDetails(
      'weather_channel',            // channel id
      '날씨 알림',                   // channel name
      channelDescription: '시간 예약 알림',
      importance: Importance.max,
      priority: Priority.high,
    );
    // 2) NotificationDetails 변수 선언
    final notificationDetails = NotificationDetails(android: androidDetails);

    // 3) TZDateTime 으로 오늘 12:40 계산 (지나면 내일로)
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      7,
      00,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print('[DEBUG] 예약된 알림 시간: $scheduledDate');

    // 4) zonedSchedule 호출 (최신 버전 시그니처)
    await _plugin.zonedSchedule(
      43,                              // 알림 ID
      '매일 푸시 알림',                 // 제목
      '지금은 12시 40분입니다!',         // 본문
      scheduledDate,                   // 첫 실행 시각
      notificationDetails,             // NotificationDetails
      androidScheduleMode:
      AndroidScheduleMode.exactAllowWhileIdle,      // Doze 모드에서도 정확히
      matchDateTimeComponents: DateTimeComponents.time,  // 매일 같은 시각에 반복
    );
  }
  static Future<void> fetchWeatherAndNotify(String apiKey) async {
    try {
      final dio = Dio();
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      double lat = position.latitude;
      double lon = position.longitude;
      print('[DEBUG] 현재 위치: $lat, $lon');

      final weatherResp = await dio.get(WEATHER_API_URL, queryParameters: {
        'lat': lat, 'lon': lon, 'appid': apiKey, 'lang': 'kr'
      });

      final pollutionResp = await dio.get(AIR_POLLUTION_API_URL, queryParameters: {
        'lat': lat, 'lon': lon, 'appid': apiKey
      });

      final weather = weatherResp.data;
      final air = pollutionResp.data;
      final description = weather['weather'][0]['description'];
      final pm10 = air['list'][0]['components']['pm10'];

      print('[DEBUG] 날씨: $description, PM10: $pm10');

      if (pm10 <= 800) {
        await showNotification(
          title: '러닝하기 좋은날!',
          body: '날씨: $description, 미세먼지: ${pm10.toStringAsFixed(1)} µg/m³',
          id: 2,
        );
      } else {
        print('[INFO] 조건 미충족: 알림 생략');
      }
    } catch (e) {
      print('[ERROR] 날씨 확인 실패: $e');
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('[DEBUG] Workmanager task 실행됨: $task');
    final apiKey = inputData?['apiKey'];

    if (apiKey == null || apiKey.isEmpty) {
      print('[ERROR] inputData에 apiKey 없음');
      return Future.value(false);
    }

    await PushNotificationService.initializeBackground();
    await PushNotificationService.fetchWeatherAndNotify(apiKey);

    return Future.value(true);
  });
}


