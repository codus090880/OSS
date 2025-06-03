import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final FlutterSecureStorage storage = FlutterSecureStorage();
  static final Dio dio = Dio(BaseOptions(
    baseUrl: 'https://a10e-121-160-204-245.ngrok-free.app',
  ));

  static final Dio authDio = Dio(BaseOptions(
    baseUrl: 'https://a10e-121-160-204-245.ngrok-free.app',
  ));


  static DateTime? getTokenExpiration(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = base64Url.normalize(parts[1]);
      final decoded = json.decode(utf8.decode(base64Url.decode(payload)));
      final exp = decoded['exp'];
      if (exp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (_) {
      return null;
    }
  }
  static Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'ACCESS_TOKEN');
    if (token == null) return false;

    final expire = getTokenExpiration(token);
    if (expire != null && DateTime.now().isBefore(expire)) {
      return true;
    }

    return await refreshTokens();
  }

  static Future<bool> refreshTokens() async {
    final refreshToken = await storage.read(key: 'REFRESH_TOKEN');
    if (refreshToken == null) return false;

    try {
      final response = await authDio.post(
        '/api/token/',
        options: Options(headers: {
          'Authorization': 'Bearer $refreshToken',
        }),
      );

      final newAccess = response.data['access'];
      final newRefresh = response.data['refresh'];

      await storage.write(key: 'ACCESS_TOKEN', value: newAccess);
      await storage.write(key: 'REFRESH_TOKEN', value: newRefresh);

      dio.options.headers['Authorization'] = 'Bearer $newAccess';
      return true;
    } catch (_) {
      return false;
    }
  }

  static void setupInterceptor() {
    dio.interceptors.clear();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'ACCESS_TOKEN');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode == 401) {
            final success = await refreshTokens();
            if (success) {
              final newToken = await storage.read(key: 'ACCESS_TOKEN');
              e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final clonedRequest = await dio.fetch(e.requestOptions);
              return handler.resolve(clonedRequest);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }
}