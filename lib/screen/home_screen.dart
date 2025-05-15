import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/rounded_shadow_box.dart';


class MarathonEvent {
  final String name;
  final DateTime date;
  final String course;
  final String url;

  MarathonEvent({
    required this.name,
    required this.date,
    required this.course,
    required this.url,
  });
}


class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomeBody(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(
          currentIndex: 0,
          onTap: (i) => Navigator.pushReplacementNamed(
            context,
            ['/home', '/running', '/course', '/profile'][i],
          ),
        ),
      ),
    );
  }
}


class HomeBody extends StatefulWidget {
  @override
  _HomeBodyState createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  // 더미 5개 이벤트
  final List<MarathonEvent> _events = [
    MarathonEvent(
      name: '서울 마라톤',
      date: DateTime(2025, 3, 15),
      course: 'Full, Half',
      url: 'http://ansanmarathon.co.kr/',
    ),
    MarathonEvent(
      name: '부산 바다 마라톤',
      date: DateTime(2025, 4, 18),
      course: '10km, 5km',
      url: 'http://ansanmarathon.co.kr/',
    ),
    MarathonEvent(
      name: '대구 하프 마라톤',
      date: DateTime(2025, 5, 10),
      course: 'Half',
      url: 'http://ansanmarathon.co.kr/',
    ),
    MarathonEvent(
      name: '광주 푸른길 마라톤',
      date: DateTime(2025, 6, 7),
      course: '10km',
      url: 'http://ansanmarathon.co.kr/',
    ),
    MarathonEvent(
      name: '인천 송도 마라톤',
      date: DateTime(2025, 7, 20),
      course: '5km',
      url: 'http://ansanmarathon.co.kr/',
    ),
  ];

  int _visibleCount = 2;

  void _toggleMore() {
    setState(() {
      if (_visibleCount < _events.length) {
        _visibleCount = (_visibleCount + 3).clamp(0, _events.length);
      } else {
        _visibleCount = 2;
      }
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('페이지를 열 수 없습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = DateFormat.M('ko_KR').format(now);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TopBar(),
          SizedBox(height: 25),

          RoundedShadowBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('마라톤 도전해봐요!',
                    style:
                    TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                Text('$currentMonth',
                    style: TextStyle(fontSize: 20, color: Colors.black)),
                SizedBox(height: 20),


                Column(
                  children: [
                    for (var e in _events.take(_visibleCount))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => _launchUrl(e.url),
                          child: _buildListItem(e),
                        ),
                      ),

                    if (_events.length > 2)
                      TextButton(
                        onPressed: _toggleMore,
                        child: Text(
                          _visibleCount < _events.length ? '더 보기 +' : '접기',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 20),
              ],
            ),
          ),

          SizedBox(height: 30),
          RoundedShadowBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('최근 인기있는 코스',
                      style: TextStyle(fontSize: 16, color: Colors.black)),
                  SizedBox(height: 10),
                  Text('리뷰 보기',
                      style: TextStyle(fontSize: 16, color: Colors.black)),
                ],
              ),
            ),
          ),
          SizedBox(height: 50),

        ],
      ),
    );
  }

  Widget _buildListItem(MarathonEvent e) {
    final dateStr = DateFormat('yyyy.MM.dd').format(e.date);
    return RoundedShadowBox(
      height: 80,
      width: double.infinity,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.name,
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(dateStr,
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF8E8E93))),
                      SizedBox(width: 12),
                      Text(e.course,
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF8E8E93))),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

/*import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/rounded_shadow_box.dart';

/// 1) MarathonEvent 모델
class MarathonEvent {
  final String name;
  final DateTime date;
  final String course;
  final String url;

  MarathonEvent({
    required this.name,
    required this.date,
    required this.course,
    required this.url,
  });

  factory MarathonEvent.fromJson(Map<String, dynamic> json) {
    return MarathonEvent(
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
      course: json['course'] as String,
      url: json['url'] as String,
    );
  }
}

/// 2) HomeScreen
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomeBody(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(
          currentIndex: 0,
          onTap: (i) => Navigator.pushReplacementNamed(
            context,
            ['/home', '/running', '/course', '/profile'][i],
          ),
        ),
      ),
    );
  }
}

/// 3) HomeBody: 서버 요청 + 더보기/접기
class HomeBody extends StatefulWidget {
  @override
  _HomeBodyState createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  final Dio _dio = Dio();
  List<MarathonEvent> _events = [];
  bool _loading = true;
  int _visibleCount = 2;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      final resp = await _dio.get('https://your.api.server/marathons');
      final data = resp.data as List<dynamic>;
      setState(() {
        _events = data
            .map((e) => MarathonEvent.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('마라톤 이벤트 로드 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('대회 정보를 불러오는 데 실패했습니다.')),
      );
    }
  }

  void _toggleMore() {
    setState(() {
      if (_visibleCount < _events.length) {
        _visibleCount = (_visibleCount + 3).clamp(0, _events.length);
      } else {
        _visibleCount = 2;
      }
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('페이지를 열 수 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = DateFormat.M('ko_KR').format(now);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TopBar(),
          SizedBox(height: 25),

          /// 상단 박스
          RoundedShadowBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('마라톤 도전해봐요!',
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                Text('$currentMonth월',
                    style: TextStyle(fontSize: 20, color: Colors.black)),
                SizedBox(height: 20),

                // 로딩 / 빈 상태 / 리스트
                if (_loading)
                  Center(child: CircularProgressIndicator())
                else if (_events.isEmpty)
                  Center(child: Text('현재 접수 중인 대회가 없습니다.'))
                else
                  Column(
                    children: [
                      for (var e in _events.take(_visibleCount))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () => _launchUrl(e.url),
                            child: _buildListItem(e),
                          ),
                        ),

                      if (_events.length > 2)
                        TextButton(
                          onPressed: _toggleMore,
                          child: Text(
                            _visibleCount < _events.length
                                ? '더 보기 +'
                                : '접기',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                    ],
                  ),

                SizedBox(height: 20),
              ],
            ),
          ),

          SizedBox(height: 30),

          /// 하단 박스
          RoundedShadowBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('최근 인기있는 코스',
                      style: TextStyle(fontSize: 16, color: Colors.black)),
                  SizedBox(height: 10),
                  Text('리뷰 보기',
                      style: TextStyle(fontSize: 16, color: Colors.black)),
                ],
              ),
            ),
          ),

          SizedBox(height: 50),
        ],
      ),
    );
  }

  /// 리스트 아이템 빌더
  Widget _buildListItem(MarathonEvent e) {
    final dateStr = DateFormat('yyyy.MM.dd').format(e.date);
    return RoundedShadowBox(
      height: 80,
      width: double.infinity,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.name,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(dateStr,
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF8E8E93))),
                      SizedBox(width: 12),
                      Text(e.course,
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF8E8E93))),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
[
  {
    "name": "더 레이스 서울 21k",
    "date": "2025-04-06",
    "course": "Half, 10km",
    "url": "http://ansanmarathon.co.kr/"
  },
  …
]
 */
