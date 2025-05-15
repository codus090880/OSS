import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';


const String WEATHER_API_KEY = '';
const String WEATHER_API_URL = 'https://api.openweathermap.org/data/2.5/weather';
const String AIR_POLLUTION_API_URL = 'https://api.openweathermap.org/data/2.5/air_pollution';

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
        android: androidInit,
        iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(initSettings);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("위치 서비스가 활성화되어 있지 않습니다.");
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('위치 권한이 거부되었습니다.');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      print('위치 권한이 영구 거부되었습니다.');
      return;
    }
  }

  static Future<void> showNotification({required String title, required String body, int id = 0}) async {
    const androidDetails = AndroidNotificationDetails(
      'weather_channel',
      '날씨 알림',
      channelDescription: '매일 아침 러닝 가능 여부 알림',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, notificationDetails);
  }

  static Future<void> fetchWeatherAndNotify() async {
    try {
      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      double lat = position.latitude;
      double lon = position.longitude;

      // 날씨 API 요청 URL 생성
      final weatherUrl = Uri.parse(
          '$WEATHER_API_URL?lat=$lat&lon=$lon&appid=$WEATHER_API_KEY&lang=kr'
      );
      // 대기오염 API 요청 URL 생성
      final pollutionUrl = Uri.parse(
          '$AIR_POLLUTION_API_URL?lat=$lat&lon=$lon&appid=$WEATHER_API_KEY'
      );

      // API 요청
      final weatherResp = await http.get(weatherUrl);
      final pollutionResp = await http.get(pollutionUrl);

      if (weatherResp.statusCode == 200 && pollutionResp.statusCode == 200) {
        final weatherJson = json.decode(weatherResp.body);
        final pollutionJson = json.decode(pollutionResp.body);

        final weatherMain = (weatherJson['weather'] as List).first['main'] as String;
        final pm10 = pollutionJson['list'][0]['components']['pm10'] as num;

        // 조건 판단
        if (weatherMain == 'Clear' && pm10 <= 50) {
          await showNotification(
            title: '러닝하기 좋은날!',
            body: '오늘 날씨: 맑음, 미세먼지: ${pm10}µg/m³',
            id: 2, // 다른 알림과 구분하기 위한 ID
          );
        }
      }
    } catch (e) {
      // 예외 처리
      print('Weather/Location error: $e');
    }
  }
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await PushNotificationService.initialize();
    await PushNotificationService.fetchWeatherAndNotify();
    return Future.value(true);
  });
}