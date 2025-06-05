import 'package:flutter/material.dart';
import 'dart:io';
import 'package:prunners/screen/change_password_screen.dart';
import 'package:prunners/screen/delete_account_screen.dart';
import 'package:prunners/screen/reset_password_screen.dart';
import 'package:prunners/screen/term_of_use_screen.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/rounded_shadow_box.dart';
import 'package:prunners/screen/profile_screen.dart';
import 'package:workmanager/workmanager.dart';
import 'package:prunners/model/push.dart';
import 'package:prunners/model/local_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prunners/screen/login_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class Setting extends StatefulWidget {
  const Setting({Key? key}) : super(key: key);

  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  bool _pushEnabled = false;

  String? _nickname;
  String? _profileUrl;
  String? _localImagePath;
  bool _isProfileLoading = true;

  final List<_MenuItem> _menuItems = const [
    _MenuItem(icon: Icons.person_outline, label: '프로필 설정'),
    _MenuItem(icon: Icons.lock,         label: '비밀번호 변경'),
    _MenuItem(icon: Icons.description,  label: '이용 약관'),
    _MenuItem(icon: Icons.notifications,label: '푸쉬 알림'),
    _MenuItem(icon: Icons.delete_sweep, label: '캐시 삭제'),
    _MenuItem(icon: Icons.logout,       label: '로그아웃'),
    _MenuItem(icon: Icons.delete,       label: '회원탈퇴'),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileFromPrefs();
    _loadLocalProfileImage();
    _loadPushSetting();
  }

  Future<void> _loadProfileFromPrefs() async {
    final name = await LocalManager.getNickname();
    final url = await LocalManager.getProfileUrl();
    setState(() {
      _nickname = name;
      _profileUrl = url;
      _isProfileLoading = false;
    });
  }

  Future<void> _loadLocalProfileImage() async {
    final savedPath = await LocalManager.getProfileImagePath();
    if (savedPath != null && savedPath.isNotEmpty) {
      final file = File(savedPath);
      if (await file.exists()) {
        setState(() {
          _localImagePath = savedPath;
        });
      } else {
        await LocalManager.setProfileImagePath('');
      }
    }
  }

  Future<void> _loadPushSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('pushEnabled') ?? false;
    setState(() => _pushEnabled = enabled);
    if (_pushEnabled) _registerWeatherTask();
  }

  Future<void> _registerWeatherTask() async {
    await PushNotificationService.initialize();
    Workmanager().registerPeriodicTask(
      'weatherTask',
      'weatherTask',
      frequency: Duration(days: 1),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  Future<void> _cancelWeatherTask() async {
    await Workmanager().cancelByUniqueName('weatherTask');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
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
                  _isProfileLoading
                      ? SizedBox(
                    width: 48, height: 48,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : (_buildProfileAvatar()),
                  SizedBox(width: 12),
                  Text(
                    _isProfileLoading
                        ? '불러오는 중...'
                        : (_nickname ?? '사용자'),
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
                    if (i.isOdd) return Divider(
                      height: 1, thickness: 1,
                      color: Colors.black.withOpacity(0.1),
                    );
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

  Widget _buildProfileAvatar() {
    if (_localImagePath != null) {
      return ClipOval(
        child: Image.file(
          File(_localImagePath!),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    } else if (_profileUrl != null && _profileUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _profileUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Icon(Icons.account_circle, size: 48, color: Colors.grey);
    }
  }

  Widget _buildMenuRow(_MenuItem item) {
    Widget trailing;
    if (item.label == '푸쉬 알림') {
      trailing = Switch(
        value: _pushEnabled,
        onChanged: (v) async {
          setState(() => _pushEnabled = v);
          final prefs = await SharedPreferences.getInstance();
          prefs.setBool('pushEnabled', v);
          if (v) _registerWeatherTask(); else _cancelWeatherTask();
        },
      );
    } else {
      trailing = Icon(
        Icons.arrow_forward_ios, size: 16,
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
        } else if (item.label == '비밀번호 변경') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChangePasswordScreen()),
          );
        } else if (item.label == '이용 약관') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TermOfUseScreen()),
          );
        } else if (item.label == '푸쉬 알림') {
        }
        else if (item.label == '캐시 삭제') {
          _showClearCacheDialog();
        }
        else if (item.label == '로그아웃') {
          logout(context);
        }
        else if (item.label == '회원탈퇴') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DeleteAccountScreen()),
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
                  fontSize: 16, fontWeight: FontWeight.w400,
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

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('캐시 삭제'),
          content: Text('로컬에 저장된 모든 데이터를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              child: Text('아니오'),
              onPressed: () => Navigator.of(context).pop(), // 다이얼로그 닫기
            ),
            TextButton(
              child: Text('예'),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.of(context).pop(); // 다이얼로그 닫기

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('캐시가 삭제되었습니다.')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

Future<void> logout(BuildContext context) async {
  final storage = FlutterSecureStorage();
  await storage.delete(key: 'ACCESS_TOKEN');
  await storage.delete(key: 'REFRESH_TOKEN');
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
  );
}

class _MenuItem {
  final IconData icon;
  final String label;
  const _MenuItem({required this.icon, required this.label});
}
