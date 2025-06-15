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
    AuthService.setupInterceptor();
    _fetchRecords();
    _fetchReport();
  }

  Future<void> _fetchRecords() async {
    try {
      final dio = AuthService.dio;
      final response = await dio.get('/record/');

      // ✅ 1️⃣ 서버 응답 전체 출력
      print('[DEBUG] /record/ response: ${response.data}');

      final data = response.data as List<dynamic>;

      final grouped = <DateTime, List<RunSummary>>{};

      for (var item in data) {
        // ✅ 2️⃣ 각 item 확인
        print('[DEBUG] item: $item');

        final summary = RunSummary.fromJson(item as Map<String, dynamic>);

        // ✅ 3️⃣ 변환된 summary 확인
        print('[DEBUG] RunSummary: '
            'date=${summary.dateTime}, '
            'distance=${summary.distanceKm}, '
            'elapsedTime=${summary.elapsedTime}, '
            'avgSpeed=${summary.averageSpeedKmh}, '
            'calories=${summary.calories}');

        final key = DateTime(
          summary.dateTime.year,
          summary.dateTime.month,
          summary.dateTime.day,
        );

        grouped.putIfAbsent(key, () => []).add(summary);
      }

      // ✅ 4️⃣ grouped Map 확인
      print('[DEBUG] grouped records:');
      grouped.forEach((key, list) {
        print('  $key → ${list.length} record(s)');
      });

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

      // 1️⃣ 요청 시작 로그
      debugPrint('🟢 _fetchReport: 요청 시작 to /api/ai_feedback/');

      final response = await dio.get('/api/api/ai_feedback/');

      // 2️⃣ 상태 코드 및 전체 응답 로그
      debugPrint('🟢 _fetchReport: statusCode = ${response.statusCode}');
      debugPrint('🟢 _fetchReport: headers = ${response.headers.map}');
      debugPrint('🟢 _fetchReport: raw data = ${response.data}');

      final data = response.data;

      // 3️⃣ 데이터 타입 및 키 유무 확인
      debugPrint('🟢 _fetchReport: data.runtimeType = ${data.runtimeType}');
      if (data is Map) {
        debugPrint('🟢 _fetchReport: contains ai_feedback key? ${data.containsKey('ai_feedback')}');
        if (data.containsKey('ai_feedback')) {
          debugPrint('🟢 _fetchReport: ai_feedback value = ${data['ai_feedback']}');
        }
      }

      // 4️⃣ 최종 파싱
      final reportText = (data is Map && data.containsKey('ai_feedback'))
          ? data['ai_feedback'].toString()
          : data.toString();

      debugPrint('🟢 _fetchReport: reportText = $reportText');

      setState(() {
        _userReport = reportText;
        _loadingReport = false;
      });
    } catch (e, st) {
      // 5️⃣ 에러 발생 시 전체 스택트레이스 로그
      debugPrint('❌ _fetchReport Error: $e');
      debugPrint('❌ StackTrace: $st');
      setState(() {
        _userReport = 'AI 리포트를 생성하기 위해, 우선 5번의 러닝이 필요합니다!';
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
                leading: Icon(Icons.info_outline),
                title: Text('정보 보기'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostRunScreen(summary: summary),
                    ),
                  );
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
      //backgroundColor: const Color(0xFFF7F8F9),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(title: '나의 기록'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1) 월·년 네비게이션
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: () => setState(() {
                    _focusedDay =
                        DateTime(_focusedDay.year, _focusedDay.month - 1);
                  }),
                ),
                Text(
                  '${_focusedDay.year}년 ${_focusedDay.month}월',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: () => setState(() {
                    _focusedDay =
                        DateTime(_focusedDay.year, _focusedDay.month + 1);
                  }),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 2) 달력
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
              onPageChanged: (focused) => setState(() {
                _focusedDay = focused;
                _selectedDay = null;
              }),
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

            const SizedBox(height: 12),

            // 3) 사용자 리포트
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
                    side:
                    BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Text(
                  _userReport ?? '표시할 리포트가 없습니다.',
                  style:
                  TextStyle(fontSize: 14, color: Color(0xFF333333)),
                ),
              ),

            const SizedBox(height: 12),

            // 4) 기록 로딩 / 리스트
            if (_loadingRecords)
              Center(child: CircularProgressIndicator()),

            if (!_loadingRecords && _selectedDay != null)
              ..._recordsByDate[
              DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)]!
                  .map(
                    (summary) => GestureDetector(
                  onTap: () => _showOptionsMenu(summary),
                  child: ActivityFrame(summary: summary),
                ),
              )
                  .toList(),

            const SizedBox(height: 16),
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
