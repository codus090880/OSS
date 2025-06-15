import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/grey_box.dart';
import 'package:prunners/model/auth_service.dart';

class RunningMate {
  final String nickname;
  final String? imageUrl;

  RunningMate({
    required this.nickname,
    required this.imageUrl,
  });

  factory RunningMate.fromJson(Map<String, dynamic> json) {
    return RunningMate(
      nickname: json['nickname'] as String,
      imageUrl: json['imageUrl'] as String?, // JSON 키를 정확히 맞춰야 합니다.
    );
  }
}

class AddRunningmate extends StatefulWidget {
  @override
  _AddRunningmateState createState() => _AddRunningmateState();
}

class _AddRunningmateState extends State<AddRunningmate> {
  final TextEditingController _controller = TextEditingController();
  final Dio _dio = AuthService.dio;  // JWT 인터셉터가 이미 적용된 dio
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
      print('🔍 검색 시작 - query: $query');
      final fullUri = _dio.options.baseUrl + '/search_mates/?q=$query';
      print('🔍 전체 요청 URL: $fullUri');

      final resp = await _dio.get(
        '/search_mates/',
        queryParameters: {'q': query},
      );

      print('✅ 응답 statusCode: ${resp.statusCode}');
      print('✅ resp.data (type: ${resp.data.runtimeType}): ${resp.data}');

      if (resp.statusCode != 200) {
        throw Exception('서버 상태코드: ${resp.statusCode}');
      }

      // resp.data가 List냐를 확인
      if (resp.data is! List) {
        print('⛔️ resp.data가 List가 아닙니다. => ${resp.data.runtimeType}');
        throw Exception('API 응답이 List 형식이 아닙니다.');
      }

      final dataList = (resp.data as List).cast<Map<String, dynamic>>();
      setState(() {
        _results = dataList.map((json) {
          return RunningMate.fromJson(json);
        }).toList();
      });
    } catch (e, s) {
      print('🚨 검색 중 예외 발생: $e');
      print(s);
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
                          child: mate.imageUrl != null
                              ? Image.network(
                            mate.imageUrl!,
                            width: 57,
                            height: 57,
                            fit: BoxFit.cover,
                          )
                              : Container(
                            width: 57,
                            height: 57,
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.person,
                              color: Colors.grey.shade500,
                              size: 32,
                            ),
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
