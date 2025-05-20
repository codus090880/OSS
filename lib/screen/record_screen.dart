import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/model/auth_service.dart';
import 'package:prunners/screen/write_review_screen.dart';

// Model for running record
class RunningRecord {
  final int id;
  final DateTime date;
  final String imageUrl;
  final double distance;
  final Duration time;
  final String pace;

  RunningRecord({
    required this.id,
    required this.date,
    required this.imageUrl,
    required this.distance,
    required this.time,
    required this.pace,
  });

  factory RunningRecord.fromJson(Map<String, dynamic> json) {
    return RunningRecord(
      id: json['id'],
      date: DateTime.parse(json['date']),
      imageUrl: json['image_url'],
      distance: (json['distance'] as num).toDouble(),
      time: Duration(seconds: json['duration_seconds']),
      pace: json['pace'],
    );
  }
}

class RecordScreen extends StatefulWidget {
  @override
  _RecordScreenState createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _loading = true;
  Map<DateTime, List<RunningRecord>> _recordsByDate = {};

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  /// 서버로 GET 요청을 보내고, 받은 JSON을 날짜별로 그룹화합니다.
  Future<void> _fetchRecords() async {
    try {
      final dio = AuthService.dio;
      final response = await dio.get('/records');
      final data = response.data as List<dynamic>;

      final grouped = <DateTime, List<RunningRecord>>{};
      for (var item in data) {
        final record = RunningRecord.fromJson(item);
        final key = DateTime(record.date.year, record.date.month, record.date.day);
        grouped.putIfAbsent(key, () => []).add(record);
      }

      setState(() {
        _recordsByDate = grouped;
        _loading = false;
      });
    } catch (e) {
      print('[ERROR] fetching records: $e');
      setState(() => _loading = false);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(title: '나의 기록'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                    });
                  },
                ),
                Text(
                  '${_focusedDay.year}년 ${_focusedDay.month}월',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            // 달력
            TableCalendar(
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              headerVisible: false,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (d) => _selectedDay != null && _isSameDay(d, _selectedDay!),
              eventLoader: (d) => _recordsByDate[DateTime(d.year, d.month, d.day)] ?? [],
              onDaySelected: (selected, focused) {
                final key = DateTime(selected.year, selected.month, selected.day);
                setState(() {
                  _selectedDay = _recordsByDate.containsKey(key) ? selected : null;
                  _focusedDay = focused;
                });
              },
              onPageChanged: (focused) {
                setState(() {
                  _focusedDay = focused;
                  _selectedDay = null;
                });
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (ctx, date, _) {
                  final key = DateTime(date.year, date.month, date.day);
                  final hasEvent = _recordsByDate.containsKey(key);
                  if (hasEvent) {
                    final isSel = _selectedDay != null && _isSameDay(date, _selectedDay!);
                    return Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSel ? Colors.green[700] : Colors.green,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }
                  return Center(child: Text('${date.day}'));
                },
              ),
            ),

            // 로딩 중일 때
            if (_loading)
              Expanded(child: Center(child: CircularProgressIndicator())),

            // 선택된 날짜의 기록 리스트
            if (!_loading && _selectedDay != null) ...[
              SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: _recordsByDate[
                  DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)
                  ]!
                      .map((record) => GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WriteReviewScreen()),
                    ),
                    child: ActivityFrame(record: record),
                  ))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(
          currentIndex: 3,
          onTap: (i) {
            const routes = ['/home', '/running', '/course', '/profile'];
            Navigator.pushReplacementNamed(context, routes[i]);
          },
        ),
      ),
    );
  }
}

// 각 기록 카드 UI
class ActivityFrame extends StatelessWidget {
  final RunningRecord record;
  const ActivityFrame({Key? key, required this.record}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 시간을 "분:초" 문자열로 포맷
    String fmt(Duration d) {
      final m = d.inMinutes;
      final s = d.inSeconds % 60;
      return '$m:${s.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadows: [BoxShadow(color: Color(0x192E3176), blurRadius: 28, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          // 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              record.imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(
                width: 70,
                height: 70,
                color: Colors.grey[300],
                child: Icon(Icons.image_not_supported, size: 32, color: Colors.grey[600]),
              ),
            ),
          ),
          SizedBox(width: 12),
          // 텍스트 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.date.year}. ${record.date.month}. ${record.date.day}',
                  style: TextStyle(fontSize: 11, color: Color(0xFF333333)),
                ),
                SizedBox(height: 4),
                Text(
                  '${record.distance.toStringAsFixed(2)} km',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Opacity(opacity: 0.7, child: Text('${fmt(record.time)} 시간', style: TextStyle(fontSize: 11))),
                Opacity(opacity: 0.7, child: Text('${record.pace} 페이스', style: TextStyle(fontSize: 11))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
