import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/model/auth_service.dart';
import 'package:prunners/screen/write_review_screen.dart';
import 'package:prunners/screen/after_running.dart';
import '../widget/running_controller.dart';

class RecordScreen extends StatefulWidget {
  @override
  _RecordScreenState createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _loadingRecords = true;
  bool _loadingReport = true;

  Map<DateTime, List<RunSummary>> _recordsByDate = {};
  String? _userReport;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
    _fetchReport();
  }

  Future<void> _fetchRecords() async {
    try {
      final dio = AuthService.dio;
      final response = await dio.get('/records');
      final data = response.data as List<dynamic>;

      final grouped = <DateTime, List<RunSummary>>{};
      for (var item in data) {
        final summary = RunSummary.fromJson(item as Map<String, dynamic>);
        final key = DateTime(
          summary.dateTime.year,
          summary.dateTime.month,
          summary.dateTime.day,
        );
        grouped.putIfAbsent(key, () => []).add(summary);
      }

      setState(() {
        _recordsByDate = grouped;
        _loadingRecords = false;
      });
    } catch (e) {
      print('[ERROR] fetching records: $e');
      setState(() => _loadingRecords = false);
    }
  }

  Future<void> _fetchReport() async {
    try {
      final dio = AuthService.dio;
      final response = await dio.get('/api/ai_feedback/');
      final data = response.data;
      final reportText = (data is Map && data.containsKey('report'))
          ? data['report'].toString()
          : data.toString();

      setState(() {
        _userReport = reportText;
        _loadingReport = false;
      });
    } catch (e) {
      print('[ERROR] fetching report: $e');
      setState(() {
        _userReport = '리포트를 불러오는 중 오류가 발생했습니다.';
        _loadingReport = false;
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _showOptionsMenu(RunSummary summary) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.rate_review),
                title: Text('리뷰 쓰기'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => WriteReviewScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('정보 보기'),
                onTap: () {
                  Navigator.pop(context);
                  /*Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AfterRunningScreen(summary: summary),
                    ),
                  );*/
                },
              ),
            ],
          ),
        );
      },
    );
  }

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
            // 월·년 네비게이션
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedDay =
                          DateTime(_focusedDay.year, _focusedDay.month - 1);
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
                      _focusedDay =
                          DateTime(_focusedDay.year, _focusedDay.month + 1);
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
              selectedDayPredicate: (d) =>
              _selectedDay != null && _isSameDay(d, _selectedDay!),
              eventLoader: (d) =>
              _recordsByDate[DateTime(d.year, d.month, d.day)] ?? [],
              onDaySelected: (selected, focused) {
                final key =
                DateTime(selected.year, selected.month, selected.day);
                setState(() {
                  _selectedDay =
                  _recordsByDate.containsKey(key) ? selected : null;
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
                    final isSel = _selectedDay != null &&
                        _isSameDay(date, _selectedDay!);
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
                            fontWeight:
                            isSel ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }
                  return Center(child: Text('${date.day}'));
                },
              ),
            ),

            SizedBox(height: 12),
            // 사용자 리포트 영역
            if (_loadingReport)
              Center(child: CircularProgressIndicator())
            else
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Text(
                  _userReport ?? '표시할 리포트가 없습니다.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
                ),
              ),
            SizedBox(height: 12),

            // 로딩 중일 때
            if (_loadingRecords)
              Expanded(child: Center(child: CircularProgressIndicator())),

            // 선택된 날짜의 RunSummary 리스트
            if (!_loadingRecords && _selectedDay != null) ...[
              Expanded(
                child: ListView(
                  children: _recordsByDate[
                  DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)]!
                      .map((summary) => GestureDetector(
                    onTap: () => _showOptionsMenu(summary),
                    child: ActivityFrame(summary: summary),
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

class ActivityFrame extends StatelessWidget {
  final RunSummary summary;
  const ActivityFrame({Key? key, required this.summary}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final date = summary.dateTime;
    final dateText = '${date.year}. ${date.month}. ${date.day}';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadows: [
          BoxShadow(color: Color(0x192E3176), blurRadius: 28, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          // 이미지 대신 여유 공간만 둠
          SizedBox(width: 0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateText,
                  style: TextStyle(fontSize: 11, color: Color(0xFF333333)),
                ),
                SizedBox(height: 4),
                Text(
                  '${summary.distanceKm.toStringAsFixed(2)} km',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Opacity(
                  opacity: 0.7,
                  child: Text(
                    '${summary.elapsedTime} 시간',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                Opacity(
                  opacity: 0.7,
                  child: Text(
                    '${summary.averageSpeedKmh.toStringAsFixed(1)} km/h',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                Opacity(
                  opacity: 0.7,
                  child: Text(
                    '${summary.calories.toStringAsFixed(0)} kcal',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
