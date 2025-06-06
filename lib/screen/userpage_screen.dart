import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/rounded_shadow_box.dart';
import 'package:prunners/screen/runningmate.dart';
import 'package:prunners/screen/setting.dart';
import 'package:prunners/screen/record_screen.dart';
import 'package:prunners/screen/level_guide_screen.dart';
import 'package:prunners/model/local_manager.dart';
import 'package:prunners/model/auth_service.dart';

class UserPageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      body: UserBody(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(
          currentIndex: 3,
          onTap: (index) {
            const routes = ['/home', '/running', '/course', '/profile'];
            if (index == 3) return;
            Navigator.pushReplacementNamed(context, routes[index]);
          },
        ),
      ),
    );
  }
}

class UserBody extends StatefulWidget {
  @override
  _UserBodyState createState() => _UserBodyState();
}

class _UserBodyState extends State<UserBody> {
  String _nickname = '사용자';
  String? _profileUrl;
  String _level = 'Starter';
  String? _localImagePath;
  double? _mannerTemp;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
    _loadLocalProfileImage();
    _fetchMannerTemp();
  }

  Future<void> _loadLocalData() async {
    final name = await LocalManager.getNickname();
    final url  = await LocalManager.getProfileUrl();
    final lvl  = await LocalManager.getLevel();
    setState(() {
      _nickname   = name;
      _profileUrl = url;
      _level      = lvl;
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
        // 파일이 없으면 Preference에서 지워두기
        await LocalManager.setProfileImagePath('');
      }
    }
  }

  Future<void> _fetchMannerTemp() async {
    setState(() => _isLoading = true);

    try {
      // SharedPreferences에서 username(=nickname) 꺼내기
      final username = await LocalManager.getNickname();

      // GET 요청 시 queryParameters로 username을 넘겨줍니다.
      final resp = await AuthService.dio.get(
        '/manner_temp/',
        queryParameters: {'username': username},
      );

      // 서버 응답 예시: { "username": "...", "manner_temp": 36.5 }
      final data = resp.data as Map<String, dynamic>;

      setState(() {
        _mannerTemp = (data['manner_temp'] as num).toDouble();
      });
    } on DioError catch (e) {
      // 에러 코드별 처리 (필요 시 UI에 토스트나 다이얼로그로 띄워도 됩니다)
      if (e.response?.statusCode == 400) {
        print('400: username 누락');
      } else if (e.response?.statusCode == 404) {
        print('404: 유저 없음');
      } else if (e.response?.statusCode == 401) {
        print('401: 인증 실패');
      } else {
        print('알 수 없는 오류: $e');
      }
    } catch (e) {
      // 기타 예외
      print('매너 온도 조회 중 오류: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  final List<_MenuItem> _menuItems = const [
    _MenuItem(icon: Icons.book,             label: '나의 기록'),
    _MenuItem(icon: Icons.group,            label: '러닝 메이트'),
    _MenuItem(icon: Icons.settings,         label: '설정'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                if (_localImagePath != null)
                  ClipOval(
                    child: Image.file(
                      File(_localImagePath!),
                      width: 100, height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                else if (_profileUrl != null && _profileUrl!.isNotEmpty)
                  ClipOval(
                    child: Image.network(
                      _profileUrl!,
                      width: 100, height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Icon(Icons.account_circle, size: 100, color: Colors.grey),
                SizedBox(width: 30),
                Text(
                  _nickname,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),

            SizedBox(height: 50),

            // Modified: manner temperature fetched from server
            Row(
              children: [
                Expanded(
                  child: RoundedShadowBox(
                    height: 80,
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
                        Row(
                          children: [
                            Icon(Icons.device_thermostat, size: 34, color: Colors.black),
                            SizedBox(width: 16),
                            Text(
                              _isLoading
                                  ? '...'
                                  : (_mannerTemp != null
                                  ? _mannerTemp!.toStringAsFixed(1)
                                  : '-'),
                              style: TextStyle(
                                fontSize: 16,
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
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LevelGuideScreen()),
                    );
                  },
                  child: RoundedShadowBox(
                    height: 80,
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
                        Row(
                          children: [
                            Icon(Icons.leaderboard, size: 34, color: Colors.black),
                            SizedBox(width: 16),
                            Text(
                              _level,
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

            SizedBox(height: 50),

            // 메뉴 목록
            RoundedShadowBox(
              width: double.infinity,
              child: SizedBox(
                height: 250,
                child: Column(
                  children: List.generate(_menuItems.length * 2 - 1, (i) {
                    if (i.isOdd) return Opacity(
                      opacity: 0.10,
                      child: Divider(height: 1, thickness: 1, color: Colors.black),
                    );
                    final item = _menuItems[i ~/ 2];
                    return Expanded(
                      child: InkWell(
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
                              MaterialPageRoute(builder: (_) => Setting()),
                            );
                          }
                          if (item.label == '나의 기록') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RecordScreen()),
                            );
                          }
                        },
                        child: Container(
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
                              Icon(Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.black.withOpacity(0.7)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            SizedBox(height: 50),
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
