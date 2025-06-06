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
    // 1) 러닝을 마치고 RunSummary 얻기
    final summary = await _controller.finishRun(context);

    final resp = await AuthService.dio.post(
      '/runhistory/',
      data: summary.toJson(),
    );

    // 3) roomId가 있으면 /end_running/ 호출 → session_id 얻기 → EvaluateScreen으로 이동
    if (widget.roomId != null) {
      int? sessionId;
      try {
        final endResp = await AuthService.dio.post<Map<String, dynamic>>(
          '/end_running/',
          data: {'room_id': widget.roomId},
        );
        debugPrint('→ /end_running/ 응답: status=${endResp.statusCode}, data=${endResp.data}');

        if (endResp.statusCode == 200 && endResp.data != null) {
          sessionId = endResp.data!['session_id'] as int;
        } else {
          throw Exception('session_id를 받아오지 못했습니다 (status ${endResp.statusCode})');
        }
      } on DioError catch (err) {
        debugPrint('=== DioError 발생 (/end_running/) ===');
        debugPrint('  .statusCode: ${err.response?.statusCode}');
        debugPrint('  .response data: ${err.response?.data}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '채팅방 종료 처리 실패: 상태 코드 ${err.response?.statusCode} - ${err.message}',
            ),
          ),
        );
      } catch (e) {
        debugPrint('=== 예외 발생 (/end_running/) ===\n  error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('채팅방 종료 처리 중 알 수 없는 에러: $e')),
        );
      }

      // 4) sessionId가 정상적으로 받아와졌다면 EvaluateScreen으로 이동
      if (sessionId != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => EvaluateScreen(
              roomId: widget.roomId!,
              sessionId: sessionId!, // 여기서 넘겨줍니다
            ),
          ),
        );
        return;
      }
      // sessionId가 null이면 PostRunScreen으로 이동하거나, 남겨진 로직을 그대로 실행할 수도 있습니다.
    }

    // 5) roomId가 없거나 sessionId 얻기에 실패했으면, 기존 PostRunScreen으로 이동
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
