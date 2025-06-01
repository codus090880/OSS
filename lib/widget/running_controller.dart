import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:prunners/model/ai_tts.dart';

class RunSummary {
  final double distanceKm;
  final String elapsedTime;
  final double calories;
  final double averageSpeedKmh;
  final double cadenceSpm;
  final List<LatLng> route;
  final DateTime dateTime;
  RunSummary({
    required this.distanceKm,
    required this.elapsedTime,
    required this.calories,
    required this.averageSpeedKmh,
    required this.cadenceSpm,
    required this.route,
    required this.dateTime,
  });

  factory RunSummary.fromJson(Map<String, dynamic> json) {
    List<LatLng> parsedRoute = [];
    if (json['route'] is List) {
      parsedRoute = (json['route'] as List<dynamic>).map((pt) {
        final lat = (pt['lat'] as num).toDouble();
        final lng = (pt['lng'] as num).toDouble();
        return LatLng(lat, lng);
      }).toList();
    }

    return RunSummary(
      distanceKm: (json['distance_km'] as num).toDouble(),
      elapsedTime: json['elapsed_time'].toString(),
      calories: (json['calories'] as num).toDouble(),
      averageSpeedKmh: (json['avg_speed_kmh'] as num).toDouble(),
      cadenceSpm: (json['cadence_spm'] as num).toDouble(),
      route: parsedRoute,
      dateTime: DateTime.parse(json['date_time'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'distance_km': distanceKm,
    'elapsed_time': elapsedTime,
    'calories': calories,
    'avg_speed_kmh': averageSpeedKmh,
    'cadence_spm': cadenceSpm,
    'date_time': dateTime.toIso8601String(),
    'route': route
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList(),
  };
}

/// Controller: 위치 권한, 활동 인식 권한, 위치 추적, 타이머, 스텝(케이던스) 관리
class RunningController {
  LatLng? initialPosition;
  final List<LatLng> route = [];
  final List<double> _speedHistory = [];
  final List<double> _cadenceHistory = [];
  final Stopwatch stopwatch = Stopwatch();
  StreamSubscription<Position>? _posSub;
  StreamSubscription<StepCount>? _stepSub;
  Timer? _timer;
  final VoidCallback onUpdate;

  bool ttsEnabled = false;
  late double weightKg;

  // 거리·칼로리·페이스
  double totalDistance = 0;
  double caloriesBurned = 0;
  double averageSpeed = 0;

  // 스텝(걸음수)
  int _initialStepCount = 0;
  int _offsetStepCount = 0;
  int stepsSinceStart = 0;

  final GeminiRepositoryImpl _gemini;
  final FlutterTts _flutterTts = FlutterTts();

  RunningController({ required this.onUpdate })
      : _gemini = GeminiRepositoryImpl();

  /// 초기화: 체중 로드 → 권한 요청 → 초기 위치 가져오기 → 트래킹 시작
  Future<void> init() async {
    // 활동 인식 권한 요청
    if (!await Permission.activityRecognition.isGranted) {
      await Permission.activityRecognition.request();
    }

    // 1) TTS+Gemini 세션 초기화
    await _flutterTts.setLanguage('ko-KR');
    await _flutterTts.setSpeechRate(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
    await _gemini.initTts();
    await _gemini.setSystemPrompt("당신은 친절한 러닝 코치입니다.");
    debugPrint("🔧 Gemini 세션 초기화 완료");

    // 2) 체중 로드
    final prefs = await SharedPreferences.getInstance();
    weightKg = prefs.getDouble('weightKg') ?? 60.0;

    // 3) 위치 권한
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      throw Exception('위치 권한이 필요합니다');
    }

    // 4) 초기 위치
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    initialPosition = LatLng(pos.latitude, pos.longitude);
    onUpdate();

    // 걸음수 스트림 구독 (초기값 확보 이후)
    _stepSub = Pedometer.stepCountStream.listen(_onStepCount,
        onError: (e) => debugPrint('StepCount error: \$e'));

    // 5) 트래킹 시작
    _startTimer();
    _startTracking();
  }

  void _onStepCount(StepCount event) {
    stepsSinceStart = _offsetStepCount + (event.steps - _initialStepCount);
    onUpdate();
  }

  void _startTracking() {
    Position? _prevPos;

    // 세션 시작 시 초기 걸음수 저장
    Pedometer.stepCountStream.first.then((first) {
      _initialStepCount = first.steps;
    });

    if (initialPosition != null) {
      route.add(initialPosition!);
      onUpdate();
    }

    // Android: 5초마다 업데이트, 거리 필터는 0m
    final androidSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,                         // 거리 변화에 상관없이
      intervalDuration: const Duration(seconds: 5), // 5초마다 위치 요청
    );

    // iOS: distanceFilter만 지정 (intervalDuration은 지원 안 됨)
    final appleSettings = AppleSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,  // 0m 이동하지 않아도 업데이트
      activityType: ActivityType.fitness, // 러닝 용도로 최적화
      pauseLocationUpdatesAutomatically: false,
    );

    _posSub = Geolocator.getPositionStream(
      locationSettings: Platform.isAndroid ? androidSettings : appleSettings,
    ).listen((pos) {
      route.add(LatLng(pos.latitude, pos.longitude));

      // 거리 계산
      if (_prevPos != null) {
        final segment = Geolocator.distanceBetween(
          _prevPos!.latitude, _prevPos!.longitude,
          pos.latitude, pos.longitude,
        );
        totalDistance += segment;
      }
      _prevPos = pos;

      // 평균 속도
      final secs = stopwatch.elapsed.inSeconds;
      if (secs > 0) {
        averageSpeed = (totalDistance / 1000) / (secs / 3600);
      }
      _speedHistory.add(averageSpeed);

      // 칼로리
      caloriesBurned = weightKg * (totalDistance / 1000) * 1.036;

      stopwatch.start();
      onUpdate();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (stopwatch.isRunning) onUpdate();
    });
    stopwatch.start();
  }

  void togglePause() {
    if (stopwatch.isRunning) {
      stopwatch.stop();
      _posSub?.pause();
      _stepSub?.pause();
      _offsetStepCount = stepsSinceStart;
    } else {
      stopwatch.start();
      _posSub?.resume();
      _stepSub?.resume();
      Pedometer.stepCountStream.first.then((event) {
        _initialStepCount = event.steps;
      });
    }
    onUpdate();
  }

  void stop() {
    _posSub?.cancel();
    _stepSub?.cancel();
    _timer?.cancel();
    stopwatch.stop();
  }

  Future<RunSummary> finishRun() async {
    stop();

    final avgSpeed = _speedHistory.isNotEmpty
        ? _speedHistory.reduce((a, b) => a + b) / _speedHistory.length
        : 0.0;
    final avgCadence = _cadenceHistory.isNotEmpty
        ? _cadenceHistory.reduce((a, b) => a + b) / _cadenceHistory.length
        : 0.0;
    debugPrint('▶▶ finishRun(): route 길이 = ${route.length}');
    return RunSummary(
      distanceKm: totalDistance / 1000,
      elapsedTime: elapsedTime,
      calories: caloriesBurned,
      averageSpeedKmh: avgSpeed,
      cadenceSpm: avgCadence,
      route: route,
      dateTime: DateTime.now(),
    );
  }

  double get cadence {
    final secs = stopwatch.elapsed.inSeconds;
    _cadenceHistory.add(stepsSinceStart / (secs / 60));
    if (secs > 0) return stepsSinceStart / (secs / 60);
    return 0;
  }

  Future<void> toggleTts() async {
    ttsEnabled = !ttsEnabled;
    debugPrint("🎙️ TTS toggled: $ttsEnabled");
    onUpdate();

    if (!ttsEnabled) return;

    _startFeedbackLoop();
  }

  void _startFeedbackLoop() {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!ttsEnabled) {
        timer.cancel();
        return;
      }
      final prompt =
          "현재 달린 거리는 ${(totalDistance / 1000).toStringAsFixed(1)}km, 평균 속도는 ${averageSpeed.toStringAsFixed(1)}km/h, 걸음 수는 $stepsSinceStart 걸음, 케이던스는 ${cadence.toStringAsFixed(1)}spm입니다.";
      try {
        await for (final response in _gemini.sendMessage(prompt)) {
          debugPrint("📝 Gemini 응답: $response");    // ← 여기에 로그 추가
          await _flutterTts.speak(response);
        }
      } catch (e, st) {
        debugPrint("❌ Gemini 호출 에러: $e\n$st");
      }
    });
  }

  String get elapsedTime {
    final d = stopwatch.elapsed;
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}



class StatusFrame extends StatelessWidget {
  final String elapsedTime;
  final VoidCallback onPause;
  final VoidCallback onMic;
  final VoidCallback onCamera;
  final bool isRunning;
  final bool ttsEnabled;
  final double distanceKm;
  final double calories;
  final double paceKmh;

  const StatusFrame({
    Key? key,
    required this.elapsedTime,
    required this.onPause,
    required this.onCamera,
    required this.onMic,
    required this.ttsEnabled,
    required this.isRunning,
    required this.distanceKm,
    required this.calories,
    required this.paceKmh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String fmt1(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
    String fmt0(double v) => v.toStringAsFixed(0);

    final distanceStr = fmt1(distanceKm);
    final calorieStr = fmt0(calories);
    final paceStr = fmt1(paceKmh);

    return Column(
      children: [
        Container(
          width: 327,
          height: 176,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadows: [
              BoxShadow(
                color: const Color(0x192E3176),
                blurRadius: 28,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // 라벨
              Positioned(
                left: 20,
                top: 20,
                child: Opacity(
                  opacity: 0.7,
                  child: Text(
                    '러닝 시간',
                    style: const TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.14,
                    ),
                  ),
                ),
              ),

              // 경과 시간
              Positioned(
                left: 20,
                top: 41,
                child: Text(
                  elapsedTime,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 28,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.28,
                  ),
                ),
              ),

              // 카메라 버튼
              Positioned(
                left: 217,
                top: 26,
                child: GestureDetector(
                  onTap: onCamera,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF5D63D1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
                ),
              ),

              // 마이크 버튼
              Positioned(
                left: 167,
                top: 26,
                child: GestureDetector(
                  onTap: onMic,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: ShapeDecoration(
                      color: ttsEnabled
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFBDBDBD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.mic, color: Colors.white),
                    ),
                  ),
                ),
              ),

              // 재생/일시정지 버튼
              Positioned(
                left: 267,
                top: 26,
                child: GestureDetector(
                  onTap: onPause,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF5D63D1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isRunning ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // 거리·칼로리·페이스 박스 (가로 한 줄)
              Positioned(
                left: 20,
                right: 20,
                top: 88,
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFF3F6FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 거리
                      Row(
                        children: [
                          const Icon(Icons.directions_run,
                              size: 20, color: Color(0xFF333333)),
                          const SizedBox(width: 4),
                          Text(
                            distanceStr,
                            style: const TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 17,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.17,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Opacity(
                            opacity: 0.7,
                            child: const Text(
                              'km',
                              style: TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 11,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.11,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 칼로리
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department,
                              size: 20, color: Color(0xFF333333)),
                          const SizedBox(width: 4),
                          Text(
                            calorieStr,
                            style: const TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 17,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.17,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Opacity(
                            opacity: 0.7,
                            child: const Text(
                              'kcal',
                              style: TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 11,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.11,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 페이스 (km/h)
                      Row(
                        children: [
                          const Icon(Icons.flash_on,
                              size: 20, color: Color(0xFF333333)),
                          const SizedBox(width: 4),
                          Text(
                            paceStr,
                            style: const TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 17,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.17,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Opacity(
                            opacity: 0.7,
                            child: const Text(
                              'km/h',
                              style: TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 11,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
