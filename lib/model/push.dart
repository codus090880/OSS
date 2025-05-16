import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await PushNotificationService.initialize();
    await PushNotificationService.fetchWeatherAndNotify();
    return Future.value(true);
  });
}

final String WEATHER_API_KEY = dotenv.env['WEATHER_API_KEY']!;
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
    const initSettings = InitializationSettings(android: androidInit);
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

  static Future<void> fetchWeatherAndNotify() async {
    try {
      final dio = Dio();

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      double lat = position.latitude;
      double lon = position.longitude;
      print('[INFO] 위치: $lat, $lon');

      final weatherResp = await dio.get(WEATHER_API_URL, queryParameters: {
        'lat': lat, 'lon': lon, 'appid': WEATHER_API_KEY, 'lang': 'kr'
      });
      final pollutionResp = await dio.get(AIR_POLLUTION_API_URL, queryParameters: {
        'lat': lat, 'lon': lon, 'appid': WEATHER_API_KEY
      });

      final weather = weatherResp.data;
      final air = pollutionResp.data;
      final description = weather['weather'][0]['description'];
      final pm10 = air['list'][0]['components']['pm10'];

      print('[INFO] 날씨: $description / 미세먼지: $pm10');


        await showNotification(
          title: '러닝하기 좋은날!',
          body: '날씨: $description, 미세먼지: ${pm10}µg/m³',
          id: 2,
        );

    } catch (e) {
      print('[ERROR] 날씨/위치 데이터 오류: $e');
    }
  }
}


