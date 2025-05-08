// lib/screen/userpage_screen.dart

import 'package:flutter/material.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/rounded_shadow_box.dart';
import 'package:prunners/screen/runningmate.dart';
import 'package:prunners/screen/setting.dart';

class UserPageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: UserBody(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          const routes = ['/home', '/running', '/profile'];
          if (index == 2) return;
          Navigator.pushReplacementNamed(context, routes[index]);
        },
      ),
    );
  }
}

class UserBody extends StatelessWidget {
  final List<_MenuItem> _menuItems = const [
    _MenuItem(icon: Icons.book,         label: '나의 기록'),
    _MenuItem(icon: Icons.workspace_premium, label: '나의 뱃지'),
    _MenuItem(icon: Icons.group,        label: '러닝 메이트'),
    _MenuItem(icon: Icons.settings,     label: '설정'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 유저 아이콘 + 이름
          Row(
            children: [
              Icon(Icons.account_circle, size: 60, color: Colors.grey),
              SizedBox(width: 12),
              Text(
                '사용자',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // 상단 작은 박스 두 개
          Row(
            children: [
              Expanded(
                child: RoundedShadowBox(
                  height: 80, // 원하시는 높이
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '매너 온도',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          letterSpacing: 0.16,
                        ),
                      ),
                      SizedBox(height: 4),
                      // 아이콘 + 값
                      Row(
                        children: [
                          Icon(
                            Icons.device_thermostat,
                            size: 34,
                            color: Colors.black,
                          ),
                          SizedBox(width: 16),
                          Text(
                            '38.0',
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              letterSpacing: 0.20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: RoundedShadowBox(
                  height: 80, // 원하시는 높이
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '레벨',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          letterSpacing: 0.16,
                        ),
                      ),
                      SizedBox(height: 4),
                      // 아이콘 + 값
                      Row(
                        children: [
                          Icon(
                            Icons.leaderboard,
                            size: 34,
                            color: Colors.black,
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Beginner',
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              letterSpacing: 0.20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // 메뉴 목록을 담은 큰 박스
          RoundedShadowBox(
            width: double.infinity,
            child: Column(
              children: List.generate(_menuItems.length * 2 - 1, (i) {
                if (i.isOdd) {
                  return Opacity(
                    opacity: 0.10,
                    child: Divider(height: 1, thickness: 1, color: Colors.black),
                  );
                }
                final item = _menuItems[i ~/ 2];
                return InkWell(
                  onTap: () {
                    if (item.label == '러닝 메이트') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RunningMate()),
                      );
                    }
                    if (item.label == '설정') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RunningMate()),
                      );
                    }
                    // TODO: 다른 메뉴 항목은 추후 구현
                  },
                  child: Container(
                    height: 48,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(item.icon, size: 20, color: Colors.black),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.black.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          SizedBox(height: 50),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  const _MenuItem({required this.icon, required this.label});
}
