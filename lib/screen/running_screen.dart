// lib/screen/running_screen.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:prunners/widget/running_controller.dart';
import 'package:flutter/scheduler.dart';  // addPostFrameCallback 사용용

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('권한 에러: ${e.toString()}')),
      );
    });
  }

  @override
  void dispose() {
    _controller.stop();
    super.dispose();
  }


  Future<void> _onCameraTap() async {
    final XFile? pickedFile = await _picker.pickImage(
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

  @override
  Widget build(BuildContext context) {
    if (_controller.initialPosition == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('러닝 준비 중'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('러닝 중'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _controller.stop();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          // 1) map을 먼저
          Expanded(
            child: KakaoMap(
              onMapCreated: (mapCtrl) {
                _mapController = mapCtrl;
                // 첫 프레임 이후 안전하게 center·level 설정
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _mapController!
                      .setCenter(_controller.initialPosition!);
                  _mapController!
                      .setLevel(
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

          // 2) 그리고 StatusFrame을 화면 맨 밑에
          StatusFrame(
            elapsedTime: _controller.elapsedTime,
            isRunning: _controller.stopwatch.isRunning,
            onPause: _controller.togglePause,
            onCamera: _onCameraTap,

            distanceKm: _controller.totalDistance / 1000,
            calories: _controller.caloriesBurned,
            paceKmh: _controller.averageSpeed,
          ),
        ],
      ),
    );
  }
}
