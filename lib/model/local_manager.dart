import 'package:shared_preferences/shared_preferences.dart';
import 'package:prunners/model/auth_service.dart';

class LocalManager {
  // 1) SharedPreferences 키 상수 정리
  static const _kNickname   = 'nickname';
  static const _kProfileUrl = 'profile_url';
  static const _kLevel      = 'level';
  static const _kGender     = 'gender';
  static const _kAge        = 'age';
  static const _kHeight     = 'height';
  static const _kWeight     = 'weight';

  /// 앱 기동 시 한 번만 호출.
  /// 로컬에 빠진 키가 있으면 서버에서 한 번에 받아와 캐싱.
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // 로컬에 저장되지 않은 키 목록
    final needs = <String>[
      _kNickname,
      _kProfileUrl,
      _kLevel,
      _kGender,
      _kAge,
      _kHeight,
      _kWeight,
    ].where((key) => prefs.get(key) == null).toList();

    if (needs.isEmpty) return;

    try {
      // /user/me/ 엔드포인트 하나로 모든 정보를 받아온다
      final resp = await AuthService.dio.get('/user/me/');
      final data = resp.data as Map<String, dynamic>;

      // 필요한 키만 로컬에 저장
      await _cacheIfNeeded(prefs, data, needs);
    } catch (_) {
      // 네트워크 오류 등 실패해도 무시
    }
  }

  // 서버에서 받아온 JSON 중, needs에 든 키만 SharedPreferences에 저장
  static Future<void> _cacheIfNeeded(
      SharedPreferences prefs,
      Map<String, dynamic> data,
      List<String> needs,
      ) async {
    if (needs.contains(_kNickname) && data['nickname'] != null) {
      await prefs.setString(_kNickname, data['nickname'] as String);
    }
    if (needs.contains(_kProfileUrl) && data['profile_url'] != null) {
      await prefs.setString(_kProfileUrl, data['profile_url'] as String);
    }
    if (needs.contains(_kLevel)) {
      final lv = (data['level'] as String?) ?? 'Starter'; // default Starter
      await prefs.setString(_kLevel, lv);
    }
    if (needs.contains(_kGender) && data['gender'] != null) {
      await prefs.setString(_kGender, data['gender'] as String);
    }
    if (needs.contains(_kAge) && data['age'] != null) {
      await prefs.setInt(_kAge, (data['age'] as num).toInt());
    }
    if (needs.contains(_kHeight) && data['height'] != null) {
      await prefs.setDouble(_kHeight, (data['height'] as num).toDouble());
    }
    if (needs.contains(_kWeight) && data['weight'] != null) {
      await prefs.setDouble(_kWeight, (data['weight'] as num).toDouble());
    }
  }

  // getter / setter

  static Future<String> getNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kNickname) ?? '사용자';
  }
  static Future<void> setNickname(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNickname, v);
  }

  static Future<String?> getProfileUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kProfileUrl);
  }
  static Future<void> setProfileUrl(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileUrl, v);
  }

  static Future<String> getLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLevel) ?? 'Starter';
  }
  static Future<void> setLevel(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLevel, v);
  }

  static Future<String?> getGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kGender);
  }
  static Future<void> setGender(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGender, v);
  }

  static Future<int?> getAge() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kAge);
  }
  static Future<void> setAge(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAge, v);
  }

  static Future<double?> getHeight() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kHeight);
  }
  static Future<void> setHeight(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kHeight, v);
  }

  static Future<double?> getWeight() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kWeight);
  }
  static Future<void> setWeight(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kWeight, v);
  }
}
