import 'dart:io';
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
    final summary = await _controller.finishRun();

    try {
      // 2) 서버에 POST (/runhistory/)
      final resp = await AuthService.dio.post(
        '/runhistory/',
        data: summary.toJson(),
      );
      if (resp.statusCode != 200) {
        throw Exception('서버 오류: ${resp.statusCode}');
      }
    } catch (e) {
      // 업로드 실패 시 에러 메시지만 띄우고 진행
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 실패: $e')),
      );
      // 원한다면 여기서 return; 으로 이동을 막을 수도 있습니다.
    }

    // 3) roomId가 있으면, 방 ID를 서버에 추가로 전송
    if (widget.roomId != null) {
      try {
        await AuthService.dio.post(
          '/runchat/room/${widget.roomId}/run_finish/',
        );
      } catch (e) {
        // 실패해도 에러 토스트만 띄우고 진행
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('채팅방 종료 처리 실패: $e')),
        );
      }
      // 4) 방이 있으면 검사 화면(EvaluateScreen)으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => EvaluateScreen(roomId: widget.roomId!)),
      );
    } else {
      // roomId가 없으면 기존처럼 PostRunScreen으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PostRunScreen(summary: summary)),
      );
    }
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
