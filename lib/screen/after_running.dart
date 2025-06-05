import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:prunners/widget/running_controller.dart'; // RunSummary 정의된 파일 경로

class PostRunScreen extends StatefulWidget {
  final RunSummary summary;

  const PostRunScreen({Key? key, required this.summary}) : super(key: key);

  @override
  State<PostRunScreen> createState() => _PostRunScreenState();
}

class _PostRunScreenState extends State<PostRunScreen> {
  KakaoMapController? _mapController;
  bool _mapReady = false;
  List<Polyline> _polylines = [];


  @override
  void initState() {
    super.initState();
  }

  void _onMapCreated(KakaoMapController controller) {
    _mapController = controller;

    setState(() {
      _mapReady = true;
      _buildPolylinesAndMarkers();
    });
  }

  void _buildPolylinesAndMarkers() {
    final routePoints = widget.summary.route;
    if (!_mapReady || routePoints.isEmpty) return;

    final polyline = Polyline(
      polylineId: 'run_route',
      points: routePoints,
      strokeColor: Colors.blue,
      strokeWidth: 6,
      strokeOpacity: 1.0,
    );

    setState(() {
      _polylines = [polyline];
    });

    _mapController!
        .fitBounds(routePoints)
        .then((_) => _mapController!.setLevel(
      1,
      options: LevelOptions(
        animate: Animate(duration: 500),
      ),
    ));
  }

  String _formatDateTime(DateTime dt) {
    final yearStr = (dt.year % 100).toString().padLeft(2, '0');
    final monthStr = dt.month.toString().padLeft(2, '0');
    final dayStr = dt.day.toString().padLeft(2, '0');
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final wk = weekdays[dt.weekday - 1];
    final hourStr = dt.hour.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');
    return '$yearStr.$monthStr.$dayStr $wk $hourStr:$minStr';
  }

  String _formatDistance(double km) {
    return km.toStringAsFixed(1).replaceAll('.', ',');
  }

  String _formatPace(double avgSpeedKmh) {
    if (avgSpeedKmh <= 0) return '00’00”';
    final pace = 60 / avgSpeedKmh;
    final minPart = pace.floor();
    final secPart = ((pace - minPart) * 60).round().clamp(0, 59);
    final secStr = secPart.toString().padLeft(2, '0');
    return '$minPart’$secStr”';
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;

    final dateText = _formatDateTime(summary.dateTime);
    final distanceText = '${_formatDistance(summary.distanceKm)} Km';
    final elapsedTimeText = summary.elapsedTime;           // "hh:mm:ss"
    final paceText = _formatPace(summary.averageSpeedKmh); // 평균 페이스
    final cadenceInt = summary.cadenceSpm.round();         // 케이던스
    final calorieStr = summary.calories.toStringAsFixed(0);// 칼로리

    final centerPoint = summary.route.isNotEmpty
        ? summary.route.first
        : LatLng(37.5665, 126.9780);

    return Scaffold(
      appBar: AppBar(
        title: const Text('러닝 결과'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        elevation: 1,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1) 상단 정보
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  distanceText,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '러닝 시간',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          elapsedTimeText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '평균 페이스',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          paceText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '케이던스',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$cadenceInt spm',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '칼로리',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$calorieStr kcal',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE0E0E0)),

          // 2) 지도
          Expanded(
            child: KakaoMap(
              onMapCreated: _onMapCreated,
              center: centerPoint,
              polylines: _polylines,
            ),
          ),
        ],
      ),
    );
  }
}
