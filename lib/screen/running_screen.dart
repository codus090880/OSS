import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:prunners/widget/running_controller.dart';
import 'package:prunners/model/auth_service.dart';
import 'package:prunners/screen/after_running.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'evaluate_screen.dart';


class RunningScreen extends StatefulWidget {
  final int? roomId;

  const RunningScreen({Key? key, this.roomId}) : super(key: key);


  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  late final RunningController _controller;
  KakaoMapController? _mapController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = RunningController(onUpdate: () => setState(() {}));
    _controller.init().catchError((e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('권한 에러: $e')));
    });
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _controller.stop();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _onCameraTap() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 80,
    );
    if (pickedFile == null) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Image.file(File(pickedFile.path)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }


  Future<bool> _onWillPop() async {
    final shouldQuit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('알림'),
        content: const Text('러닝을 중단하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('예'),
          ),
        ],
      ),
    );

    if (shouldQuit == true) {
      // 여기서 바로 _finishAndUpload()를 호출
      await _finishAndUpload();
    }
    //뒤로가기를 막기 위해 항상 false 반환
    return false;
  }

  Future<void> _finishAndUpload() async {
    debugPrint('🟢 step1: RunSummary 생성 시작');
    final summary = await _controller.finishRun(context);
    debugPrint('🟢 step2: RunSummary 생성 완료');

    final token = await AuthService.storage.read(key: 'ACCESS_TOKEN');
    debugPrint('🟢 step3: ACCESS_TOKEN 로드 완료');

    // 4) 서버에 POST (예외 허용)
    try {
      // 4.1) 업로드 페이로드 확인
      final payload = summary.toJson();
      debugPrint('🟢 step4.1: 업로드할 데이터 = $payload');

      debugPrint('🟢 step4: /upload_course 요청 시작');
      final resp = await AuthService.dio.post(
        '/upload_course/',
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('🟢 step5: /upload_course 응답 status = ${resp.statusCode}');
      // 5.1) 응답 바디 확인
      debugPrint('🟢 step5.1: /upload_course 응답 데이터 = ${resp.data}');
    } catch (e, st) {
      debugPrint('❌ /upload_course 업로드 실패: $e');
      debugPrint('❌ StackTrace: $st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드는 실패했지만 기록은 저장되었습니다.')),
      );
    }

    // 5) roomId 있으면 → /end_running 시도
    if (widget.roomId != null) {
      debugPrint('🟢 step6: roomId 감지됨 → /end_running 요청 시작');
      int? sessionId;

      try {
        final endResp = await AuthService.dio.post<Map<String, dynamic>>(
          '/end_running/',
          data: {'room_id': widget.roomId},
        );
        debugPrint('🟢 step7: /end_running 응답 status = ${endResp.statusCode}');
        debugPrint('🟢 step7.1: /end_running 응답 데이터 = ${endResp.data}');

        if (endResp.statusCode == 200 && endResp.data != null) {
          sessionId = endResp.data!['session_id'] as int;
          debugPrint('🟢 step8: session_id = $sessionId');
        } else {
          throw Exception('session_id를 받아오지 못했습니다 (status ${endResp.statusCode})');
        }
      } on DioError catch (err) {
        debugPrint('❌ stepX: DioError (/end_running) status: ${err.response?.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '채팅방 종료 처리 실패: 상태 코드 ${err.response?.statusCode} - ${err.message}',
            ),
          ),
        );
      } catch (e, st) {
        debugPrint('❌ stepX: 예외 발생 (/end_running): $e');
        debugPrint('❌ StackTrace: $st');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('채팅방 종료 처리 중 알 수 없는 에러: $e')),
        );
      }

      if (sessionId != null) {
        debugPrint('🟢 step9: EvaluateScreen으로 이동');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => EvaluateScreen(
              roomId: widget.roomId!,
              sessionId: sessionId!,
            ),
          ),
        );
        return;
      }

      debugPrint('⚠️ step10: sessionId가 null임 → PostRunScreen으로 이동 예정');
    } else {
      debugPrint('🟡 step11: roomId 없음 → PostRunScreen으로 이동 예정');
    }

    // 6) fallback: PostRunScreen으로 이동
    debugPrint('🟢 step12: PostRunScreen으로 pushReplacement');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => PostRunScreen(summary: summary)),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_controller.initialPosition == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('러닝 준비 중'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('러닝 중'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            // system back과 동일하게 onWillPop을 트리거합니다
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: KakaoMap(
                onMapCreated: (mapCtrl) {
                  _mapController = mapCtrl;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _mapController!.setCenter(_controller.initialPosition!);
                    _mapController!.setLevel(
                      1,
                      options: LevelOptions(
                        animate: Animate(duration: 500),
                        anchor: _controller.initialPosition!,
                      ),
                    );
                  });
                },
                center: _controller.initialPosition!,
                polylines: [
                  if (_controller.route.isNotEmpty)
                    Polyline(
                      polylineId: 'running_route',
                      points: _controller.route,
                      strokeColor: Colors.blue,
                      strokeWidth: 6,
                    ),
                ],
              ),
            ),
            StatusFrame(
              elapsedTime: _controller.elapsedTime,
              isRunning: _controller.stopwatch.isRunning,
              onPause: _controller.togglePause,
              onCamera: _onCameraTap,
              onMic: _controller.toggleTts,
              ttsEnabled: _controller.ttsEnabled,
              distanceKm: _controller.totalDistance / 1000,
              calories: _controller.caloriesBurned,
              paceKmh: _controller.averageSpeed,
            ),
          ],
        ),
      ),
    );
  }
}
