import 'package:flutter/material.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/rounded_shadow_box.dart';
import 'package:prunners/screen/add_runningmate.dart';
import 'package:prunners/screen/chat_screen.dart';
import 'package:prunners/screen/record_screen.dart';
import 'package:prunners/model/auth_service.dart';
import 'package:dio/dio.dart';

/// 친구 데이터 모델
class Friend {
  final String nickname;
  final String? avatarUrl;

  Friend({required this.nickname, required this.avatarUrl});

  factory Friend.fromJson(Map<String, dynamic> json) {
    // API에서 내려주는 키가 "username"과 "profile_image"이므로, 그에 맞춰 파싱
    return Friend(
      nickname: json['username'] as String,
      avatarUrl: json['profile_image'] as String?,
    );
  }
}

/// 친구 요청 데이터 모델
class FriendRequest {
  final String fromNickname;
  final String? fromAvatarUrl;

  FriendRequest({
    required this.fromNickname,
    required this.fromAvatarUrl,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      fromNickname: json['username'] as String,
      fromAvatarUrl: json['profile_image'] as String?,
    );
  }
}

/// 러닝 메이트 화면
class RunningMate extends StatefulWidget {
  @override
  _RunningMateState createState() => _RunningMateState();
}

class _RunningMateState extends State<RunningMate> {
  final Dio dio = AuthService.dio; // JWT 인증 인터셉터가 적용된 Dio 인스턴스
  List<Friend> _friends = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  /// 서버에서 친구 목록을 가져오는 함수
  Future<void> _fetchFriends() async {
    try {
      final Response<dynamic> resp = await dio.get('/list_friends/');
      print('🌟 친구 목록 API 응답 전체: ${resp.data}');
      print('🌟 응답 타입: ${resp.data.runtimeType}, statusCode: ${resp.statusCode}');

      if (resp.statusCode == 200 && resp.data is List) {
        final rawList = resp.data as List<dynamic>;
        setState(() {
          _friends = rawList
              .cast<Map<String, dynamic>>()
              .map((e) => Friend.fromJson(e))
              .toList();
          _loading = false;
        });
      } else {
        // 예기치 않은 응답 형식 또는 상태코드
        setState(() => _loading = false);
        print('✋ 예상치 못한 응답: dataType=${resp.data.runtimeType}, data=${resp.data}');
      }
    } catch (e) {
      setState(() => _loading = false);
      print('친구 목록 로드 실패: $e');
    }
  }

  /// 친구 삭제 요청 함수
  Future<void> _deleteFriend(int index) async {
    final f = _friends[index];
    try {
      // 예: /delete_friend/ 에는 삭제할 친구 username을 body에 전달해야 한다고 가정
      await dio.delete(
        '/delete_friend/',
        data: {'username': f.nickname},
      );
      setState(() => _friends.removeAt(index));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('삭제에 실패했습니다.')));
    }
  }

  /// 친구 요청 목록을 모달로 띄우는 함수
  void _showFriendRequests() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: FutureBuilder<Response<dynamic>>(
              future: dio.get('/list_pending_requests/'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('요청 목록 로드 실패'));
                }

                final Response<dynamic> resp = snapshot.data!;
                print('🌟 요청 목록 API 응답: ${resp.data}');
                print('🌟 응답 타입: ${resp.data.runtimeType}, statusCode: ${resp.statusCode}');

                if (resp.statusCode != 200) {
                  return Center(
                    child: Text('요청 목록 로드 실패 (status: ${resp.statusCode})'),
                  );
                }
                if (resp.data is! List) {
                  return Center(child: Text('잘못된 데이터 형식입니다.'));
                }

                final rawList = resp.data as List<dynamic>;
                if (rawList.isEmpty) {
                  return Center(child: Text('대기 중인 친구 요청이 없습니다.'));
                }

                final requests = rawList
                    .cast<Map<String, dynamic>>()
                    .map((json) => FriendRequest.fromJson(json))
                    .toList();

                return ListView.separated(
                  padding: EdgeInsets.all(16),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => Divider(),
                  itemBuilder: (_, i) {
                    final r = requests[i];
                    return ListTile(
                      leading: CircleAvatar(
                        // 프로필 이미지가 null이면 기본 아이콘 표시
                        backgroundImage: r.fromAvatarUrl != null
                            ? NetworkImage(r.fromAvatarUrl!)
                            : null,
                        child: r.fromAvatarUrl == null
                            ? Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(r.fromNickname),
                      subtitle: Text('님이 친구 요청을 보냈습니다.'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () async {
                              try {
                                // 예: /accept_friend_request/ 에는 보낸 사람 username을 전송
                                await dio.post(
                                  '/accept_friend_request/',
                                  data: {'from_username': r.fromNickname},
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('수락에 실패했습니다.')),
                                );
                              }
                              // 모달 닫고 새로고침
                              Navigator.pop(context);
                              _showFriendRequests();
                            },
                            child: Text('수락'),
                          ),
                          TextButton(
                            onPressed: () async {
                              try {
                                // 예: /reject_friend_request/ (엔드포인트 이름에 맞게)
                                await dio.post(
                                  '/friends/reject/',
                                  data: {'from_username': r.fromNickname},
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('거절에 실패했습니다.')),
                                );
                              }
                              Navigator.pop(context);
                              _showFriendRequests();
                            },
                            child: Text('거절'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
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
        child: AppBar(
          title: Text('러닝 메이트'),
          actions: [
            IconButton(
              icon: Icon(Icons.person_add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddRunningmate()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: _showFriendRequests,
            ),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _friends.isEmpty
          ? Center(child: Text('친구가 없습니다.'))
          : ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: _friends.length,
        itemBuilder: (_, i) {
          final f = _friends[i];
          return Dismissible(
            key: ValueKey(f.nickname),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (dir) async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('친구 삭제'),
                  content: Text(
                    '${f.nickname}님을 친구 목록에서 삭제하시겠습니까?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text('삭제'),
                    ),
                  ],
                ),
              );
              return confirm == true;
            },
            onDismissed: (_) => _deleteFriend(i),
            child: RoundedShadowBox(
              child: ListTile(
                leading: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecordScreen(),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: f.avatarUrl != null
                        ? NetworkImage(f.avatarUrl!)
                        : null,
                    child: f.avatarUrl == null
                        ? Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                ),
                title: Text(
                  f.nickname,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          friendUsername: f.nickname,
                          friendAvatarUrl: f.avatarUrl ?? '',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(
          currentIndex: 3,
          onTap: (index) {
            const routes = ['/home', '/running', '/course', '/profile'];
            Navigator.pushReplacementNamed(context, routes[index]);
          },
        ),
      ),
    );
  }
}
