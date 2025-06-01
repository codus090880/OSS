import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/grey_box.dart';
import 'package:prunners/model/auth_service.dart';

class RunningMate {
  final String nickname;
  final String imageUrl;

  RunningMate({
    required this.nickname,
    required this.imageUrl,
  });

  factory RunningMate.fromJson(Map<String, dynamic> json) {
    return RunningMate(
      nickname: json['nickname'],
      imageUrl: json['profile_url'],
    );
  }
}

class AddRunningmate extends StatefulWidget {
  @override
  _AddRunningmateState createState() => _AddRunningmateState();
}

class _AddRunningmateState extends State<AddRunningmate> {
  final TextEditingController _controller = TextEditingController();
  final Dio _dio = AuthService.dio;  // 인터셉터 적용된 dio
  List<RunningMate> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _results = [];
    });

    try {
      final resp = await _dio.get(
        '/search_mates/',
        queryParameters: {'q': query},
      );
      final data = resp.data as List;
      setState(() {
        _results = data
            .map((json) => RunningMate.fromJson(json as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('검색 중 오류가 발생했습니다.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addFriend(String friendNickname) async {
    try {
      final resp = await _dio.post(
        '/send_friend_request/',
        data: {'to_username': friendNickname},
      );
      if (resp.statusCode == 200) {
        setState(() {
          _results.removeWhere((m) => m.nickname == friendNickname);
        });
      } else {
        throw Exception('status ${resp.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('친구 추가에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(title: '친구 등록'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // 검색창
            GreyBox(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _search,
                    child: Icon(Icons.search, color: Color(0xFF8390A1)),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                      decoration: InputDecoration(
                        hintText: '닉네임',
                        hintStyle: TextStyle(
                          color: Color(0xFF8390A1),
                          fontSize: 15,
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 18),
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.cancel, size: 20, color: Colors.grey),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _results.clear());
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                ],
              ),
            ),

            SizedBox(height: 20),

            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? Center(child: Text('검색 결과가 없습니다.'))
                  : ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final mate = _results[idx];
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    height: 78,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadows: [
                        BoxShadow(
                          color: Color(0x192E3176),
                          blurRadius: 28,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.network(
                            mate.imageUrl,
                            width: 57,
                            height: 57,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            mate.nickname,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.person_add),
                          onPressed: () => _addFriend(mate.nickname),
                        ),
                      ],
                    ),
                  );
                },
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
            Navigator.pushReplacementNamed(
              context,
              index == 3 ? '/profile' : routes[index],
            );
          },
        ),
      ),
    );
  }
}
