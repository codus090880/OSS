import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller: 위치 권한 확인, 위치 추적, 타이머 관리
class RunningController {
  LatLng? initialPosition;
  final List<LatLng> route = [];
  final Stopwatch stopwatch = Stopwatch();
  StreamSubscription<Position>? _posSub;
  Timer? _timer;
  final VoidCallback onUpdate;


  late double weightKg;

  // 거리·칼로리·페이스
  double totalDistance = 0;
  double caloriesBurned = 0;
  double averageSpeed = 0;

  RunningController({ required this.onUpdate });

  /// 초기화: 체중 로드 → 권한 요청 → 초기 위치 가져오기 → 타이머·트래킹 시작
  Future<void> init() async {
    // 1) SharedPreferences에서 체중 불러오기
    final prefs = await SharedPreferences.getInstance();
    weightKg = prefs.getDouble('weightKg') ?? 60.0; // 디폴트 60kg

    // 2) 위치 권한 확인/요청
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      throw Exception('위치 권한이 필요합니다');
    }

    // 3) 현재 위치 가져와 초기 센터로 설정
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    initialPosition = LatLng(pos.latitude, pos.longitude);
    onUpdate();

    // 4) 타이머·트래킹 시작
    _startTimer();
    _startTracking();
  }

  void _startTracking() {
    Position? _prevPos;

    // 즉시 첫 좌표 저장
    if (initialPosition != null) {
      route.add(initialPosition!);
      onUpdate();
    }

    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      final cur = LatLng(pos.latitude, pos.longitude);

      // 경로 추가
      route.add(cur);

      // 1) 구간 거리 계산 (m)
      if (_prevPos != null) {
        final segment = Geolocator.distanceBetween(
          _prevPos!.latitude, _prevPos!.longitude,
          pos.latitude, pos.longitude,
        );
        totalDistance += segment;
      }
      _prevPos = pos;

      // 2) 평균 속도 계산 (km/h)
      final secs = stopwatch.elapsed.inSeconds;
      if (secs > 0) {
        averageSpeed = (totalDistance / 1000) / (secs / 3600);
      }

      // 3) 칼로리 계산 (예: 1kg당 1.036kcal/km)
      caloriesBurned = weightKg * (totalDistance / 1000) * 1.036;

      // 4) 스톱워치 시작 & 화면 갱신
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
    } else {
      stopwatch.start();
      _posSub?.resume();
    }
    onUpdate();
  }

  void stop() {
    _posSub?.cancel();
    _timer?.cancel();
    stopwatch.stop();
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
  final VoidCallback onCamera;
  final bool isRunning;
  final double distanceKm;
  final double calories;
  final double paceKmh;

  const StatusFrame({
    Key? key,
    required this.elapsedTime,
    required this.onPause,
    required this.onCamera,
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