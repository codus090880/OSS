// lib/screen/record_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/bottom_bar.dart';

class RecordScreen extends StatefulWidget {
  @override
  _RecordScreenState createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final List<DateTime> _eventDates = [
    DateTime.now(),
    // DateTime(2025, 4, 16),
    // DateTime(2025, 4, 22),
  ];

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
            // 커스텀 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month - 1,
                      );
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
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month + 1,
                      );
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            // 요일 레이블
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['일', '월', '화', '수', '목', '금', '토']
                  .map((d) => Expanded(
                child: Center(
                  child: Text(d,
                      style: TextStyle(fontWeight: FontWeight.w500)),
                ),
              ))
                  .toList(),
            ),
            SizedBox(height: 4),
            // TableCalendar
            Expanded(
              child: TableCalendar(
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) =>
                _selectedDay != null && _isSameDay(day, _selectedDay!),
                calendarFormat: CalendarFormat.month,
                headerVisible: false,
                onDaySelected: (selected, focused) {
                  if (_eventDates.any((d) => _isSameDay(d, selected))) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  }
                },
                onPageChanged: (focused) {
                  setState(() => _focusedDay = focused);
                  _selectedDay = null;
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (ctx, date, _) {
                    final isEvent = _eventDates
                        .any((d) => _isSameDay(d, date));
                    if (isEvent) {
                      final isSelected = _selectedDay != null &&
                          _isSameDay(date, _selectedDay!);
                      return Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.green[700]
                                : Colors.green,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }
                    // 이벤트 없는 날짜
                    return Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(color: Colors.black),
                      ),
                    );
                  },
                ),
              ),
            ),
            // 선택된 날짜 정보 자리 (미구현)
            if (_selectedDay != null) ...[
              SizedBox(height: 12),
              Text(
                '$_selectedDay 에 대한 정보 표시 영역',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          const routes = ['/home', '/running', '/profile'];
          if (index == 2) {
            Navigator.pushReplacementNamed(context, '/profile');
          } else {
            Navigator.pushReplacementNamed(context, routes[index]);
          }
        },
      ),
    );
  }
}
