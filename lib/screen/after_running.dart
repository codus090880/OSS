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

  void _onMapCreated(KakaoMapController controller) {
    _mapController = controller;

    if (widget.summary.route.isNotEmpty) {
      final LatLng firstPoint = widget.summary.route.first;
      _mapController!.setCenter(firstPoint);
      _mapController!.setLevel(
        6, // 숫자가 클수록 지도가 확대됩니다. (1 = 최대 축소)
        options: LevelOptions(
          animate: Animate(duration: 500),
          anchor: firstPoint,
        ),
      );
    } else {
      final LatLng defaultCenter = LatLng(37.5665, 126.9780);
      _mapController!.setCenter(defaultCenter);
      _mapController!.setLevel(
        6,
        options: LevelOptions(
          animate: Animate(duration: 500),
          anchor: defaultCenter,
        ),
      );
    }
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
    final calorieStr = summary.calories.toStringAsFixed(0); // 칼로리

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
                    // 평균 페이스
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

          Expanded(
            child: KakaoMap(
              onMapCreated: _onMapCreated,

              center: summary.route.isNotEmpty
                  ? summary.route.first
                  : LatLng(37.5665, 126.9780),

              polylines: summary.route.isNotEmpty
                  ? [
                Polyline(
                  polylineId: 'post_run_route',
                  points: summary.route,
                  strokeColor: Colors.blue,
                  strokeOpacity: 1.0,
                  strokeWidth: 6,
                ),
              ]
                  : const <Polyline>[],

              markers: summary.route.isNotEmpty
                  ? [
                Marker(
                  markerId: 'start',
                  latLng: summary.route.first,
                ),
                Marker(
                  markerId: 'end',
                  latLng: summary.route.last,
                ),
              ]
                  : const <Marker>[],
            ),
          ),
        ],
      ),
    );
  }
}
