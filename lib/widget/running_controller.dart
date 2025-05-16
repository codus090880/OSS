import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

/// Controller: 위치 권한 확인, 위치 추적, 타이머 관리
class RunningController {
  LatLng? initialPosition;
  final List<LatLng> route = [];
  final Stopwatch stopwatch = Stopwatch();
  StreamSubscription<Position>? _posSub;
  Timer? _timer;
  final VoidCallback onUpdate;

  RunningController({required this.onUpdate});

  /// 초기화: 권한 요청 → 초기 위치 가져오기 → 타이머·트래킹 시작
  Future<void> init() async {
    // 위치 권한 확인/요청
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      throw Exception('위치 권한이 필요합니다');
    }

    // 현재 위치 가져와 초기 센터로 설정
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    initialPosition = LatLng(pos.latitude, pos.longitude);
    onUpdate();

    _startTimer();
    _startTracking();
  }

  void _startTracking() {
    // 즉시 첫 좌표 저장
    if (initialPosition != null) {
      route.add(initialPosition!);
      onUpdate();
    }
    // 스트림 구독
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      route.add(LatLng(pos.latitude, pos.longitude));
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

  /// 일시정지/재개 토글
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

  /// 추적 중단
  void stop() {
    _posSub?.cancel();
    _timer?.cancel();
    stopwatch.stop();
  }

  /// 경과 시간 문자열 (HH:MM:SS)
  String get elapsedTime {
    final d = stopwatch.elapsed;
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}

/// Figma 레이아웃 기반 러닝 상태 표시 위젯
class StatusFrame extends StatelessWidget {
  final String elapsedTime;
  final VoidCallback onPause;
  final bool isRunning;

  const StatusFrame({
    Key? key,
    required this.elapsedTime,
    required this.onPause,
    required this.isRunning,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              // 러닝 시간 텍스트
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

              // 일시정지/재개 버튼
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
                      child: isRunning
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(
                            width: 2.5,
                            height: 16,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.all(Radius.circular(3)),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          SizedBox(
                            width: 2.5,
                            height: 16,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.all(Radius.circular(3)),
                              ),
                            ),
                          ),
                        ],
                      )
                          : const Icon(Icons.play_arrow, color: Colors.white),
                    ),
                  ),
                ),
              ),

              // 라벨
              Positioned(
                left: 20,
                top: 20,
                child: Opacity(
                  opacity: 0.70,
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
            ],
          ),
        ),
      ],
    );
  }
}
