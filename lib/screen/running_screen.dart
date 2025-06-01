import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:prunners/widget/running_controller.dart';
import 'package:prunners/model/auth_service.dart';
import 'package:prunners/screen/profile_screen.dart';
import 'package:prunners/screen/after_running.dart';

class RunningScreen extends StatefulWidget {
  const RunningScreen({Key? key}) : super(key: key);

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
  }

  @override
  void dispose() {
    _controller.stop();
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
      // 1) 러닝을 마치고 RunSummary를 받아온다
      final summary = await _controller.finishRun();

      // 2) PostRunScreen으로 이동 (현재 화면 제거)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PostRunScreen(summary: summary),
        ),
      );
    }
    return false;
  }

  Future<void> _finishAndUpload() async {
    final summary = await _controller.finishRun();

    try {
      final resp = await AuthService.dio.post(
        '/api/runs',
        data: summary.toJson(),
      );
      if (resp.statusCode != 200) {
        throw Exception('서버 오류: ${resp.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('업로드 실패: $e')));
      //return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ProfileScreen()),
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
