import 'package:flutter/material.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/rounded_shadow_box.dart';
import 'package:prunners/screen//profile_screen.dart';

class Setting extends StatefulWidget {
  @override
  _Setting createState() => _Setting();
}

class _Setting extends State<Setting> {
  bool _pushEnabled = false;

  final List<_MenuItem> _menuItems = const [
    _MenuItem(icon: Icons.person_outline, label: '프로필 설정'),
    _MenuItem(icon: Icons.lock,         label: '비밀번호 변경'),
    _MenuItem(icon: Icons.description,  label: '이용 약관'),
    _MenuItem(icon: Icons.notifications, label: '푸쉬 알림'),
    _MenuItem(icon: Icons.logout,       label: '로그아웃'),
    _MenuItem(icon: Icons.delete,       label: '회원탈퇴'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(title: '설정'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 유저 프로필
            RoundedShadowBox(
              width: double.infinity,
              child: Row(
                children: [
                  Icon(Icons.account_circle, size: 48, color: Colors.grey),
                  SizedBox(width: 12),
                  Text(
                    '사용자',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // 메뉴 목록
            RoundedShadowBox(
              width: double.infinity,
              child: Column(
                children: List.generate(
                  _menuItems.length * 2 - 1,
                      (i) {
                    if (i.isOdd) {
                      return Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.black.withOpacity(0.1),
                      );
                    }
                    final item = _menuItems[i ~/ 2];
                    return _buildMenuRow(item);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(
          currentIndex: 3,
          onTap: (index) {
            const routes = ['/home', '/running', '/course', '/profile'];
            if (index == 3) {
              Navigator.pushReplacementNamed(context, '/profile');
            } else {
              Navigator.pushReplacementNamed(context, routes[index]);
            }
          },
        ),
      ),
    );
  }

  Widget _buildMenuRow(_MenuItem item) {
    Widget trailing;
    if (item.label == '푸쉬 알림') {
      trailing = Switch(
        value: _pushEnabled,
        onChanged: (v) => setState(() => _pushEnabled = v),
      );
    } else {
      trailing = Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.black.withOpacity(0.7),
      );
    }

    return InkWell(
      onTap: () {
        if (item.label == '프로필 설정') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen()),
          );
        }
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
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  const _MenuItem({required this.icon, required this.label});
}