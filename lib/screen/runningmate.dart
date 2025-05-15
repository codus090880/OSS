/*import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/rounded_shadow_box.dart';
import 'package:prunners/screen/add_runningmate.dart';
import 'package:prunners/screen/chat_screen.dart';
import 'package:prunners/screen/record_screen.dart'; // RecordScreen import

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
  final Dio _dio = Dio();
  List<Friend> _friends = [];
  bool _loading = true;
  final String _myNick = '내_닉네임';

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    try {
      final resp = await _dio.get(
        'https://your.api.server/friends',
        queryParameters: {'nick': _myNick},
      );
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
      await _dio.delete(
        'https://your.api.server/friends/${f.nickname}',
      );
      setState(() => _friends.removeAt(index));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('삭제에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(
          title: '러닝 메이트',
          rightIcon: Icons.person_add,
          onRightPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddRunningmate()),
            );
          },
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
                        builder: (_) => ChatScreen(),
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
*/
import 'package:flutter/material.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/rounded_shadow_box.dart';
import 'package:prunners/screen/add_runningmate.dart';
import 'package:prunners/screen/chat_screen.dart';
import 'package:prunners/screen/record_screen.dart';

class Friend {
  final String nickname;
  final String avatarUrl;

  Friend({required this.nickname, required this.avatarUrl});
}

class RunningMate extends StatefulWidget {
  @override
  _RunningMateState createState() => _RunningMateState();
}

class _RunningMateState extends State<RunningMate> {
  List<Friend> _friends = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDummyFriends();
  }

  void _loadDummyFriends() {
    // 더미 5명
    _friends = [
      Friend(nickname: '홍길동', avatarUrl: 'https://via.placeholder.com/48'),
      Friend(nickname: '이몽룡', avatarUrl: 'https://via.placeholder.com/48'),
      Friend(nickname: '성춘향', avatarUrl: 'https://via.placeholder.com/48'),
      Friend(nickname: '강감찬', avatarUrl: 'https://via.placeholder.com/48'),
      Friend(nickname: '심청이', avatarUrl: 'https://via.placeholder.com/48'),
    ];
    // 바로 로딩 완료
    setState(() => _loading = false);
  }

  void _onFriendAction(Friend f, String action) {
    switch (action) {
      case 'chat':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen()),
        );
        break;
      case 'delete':
      // 더미라 그냥 리스트에서 제거
        setState(() => _friends.remove(f));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(
          title: '러닝 메이트',
          rightIcon: Icons.person_add,
          onRightPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddRunningmate()),
            );
          },
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
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Dismissible(
              key: ValueKey(f.nickname),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20),
                child: Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                setState(() => _friends.removeAt(i));
              },
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
                          builder: (_) => ChatScreen(),
                        ),
                      );
                    },
                  ),
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
