import 'package:flutter/material.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/rounded_shadow_box.dart';
import 'package:prunners/screen/add_runningmate.dart';
import 'package:prunners/screen/chat_screen.dart';
import 'package:prunners/screen/record_screen.dart';
import 'package:prunners/model/auth_service.dart';

class Friend {
  final String nickname;
  final String avatarUrl;

  Friend({required this.nickname, required this.avatarUrl});

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      nickname: json['nickname'],
      avatarUrl: json['avatar_url'],
    );
  }
}

class RunningMate extends StatefulWidget {
  @override
  _RunningMateState createState() => _RunningMateState();
}

class _RunningMateState extends State<RunningMate> {
  final dio = AuthService.dio;
  List<Friend> _friends = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    try {
      final resp = await dio.get('/list_friends/');
      final data = resp.data as List;
      setState(() {
        _friends = data.map((e) => Friend.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      print('친구 목록 로드 실패: $e');
    }
  }

  Future<void> _deleteFriend(int index) async {
    final f = _friends[index];
    try {
      await dio.delete('/delete_friend/');
      setState(() => _friends.removeAt(index));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('삭제에 실패했습니다.')));
    }
  }

  void _showFriendRequests() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: FutureBuilder(
              future: dio.get('/list_pending_requests/'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('요청 목록 로드 실패'));
                }
                final List reqs = (snapshot.data as dynamic).data as List;
                if (reqs.isEmpty) {
                  return Center(child: Text('대기 중인 친구 요청이 없습니다.'));
                }
                final requests = reqs.map((e) => FriendRequest.fromJson(e)).toList();
                return ListView.separated(
                  padding: EdgeInsets.all(16),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => Divider(),
                  itemBuilder: (_, i) {
                    final r = requests[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(r.fromAvatarUrl),
                      ),
                      title: Text(r.fromNickname),
                      subtitle: Text('님이 친구 요청을 보냈습니다.'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await dio.post('/accept_friend_request/');
                              // 모달 새로고침
                              setState(() {});
                              Navigator.pop(context);
                              _showFriendRequests();
                            },
                            child: Text('수락'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await dio.post('/friends/reject/');
                              setState(() {});
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
                    backgroundImage: NetworkImage(f.avatarUrl),
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
                          friendAvatarUrl: f.avatarUrl,
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

class FriendRequest {
  final String fromNickname;
  final String fromAvatarUrl;

  FriendRequest({
    required this.fromNickname,
    required this.fromAvatarUrl,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      fromNickname: json['from_nickname'],
      fromAvatarUrl: json['from_avatar_url'],
    );
  }
}
