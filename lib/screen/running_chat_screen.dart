import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:prunners/widget/chat_box.dart';
import 'package:prunners/model/running_chat_service.dart';
import 'package:prunners/model/local_manager.dart';
import 'package:prunners/screen/running_screen.dart';
import 'package:prunners/screen/matching_list_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final int roomId;
  final String initialRoomTitle;
  final bool initialIsPublic;

  const ChatRoomScreen({
    Key? key,
    required this.roomId,
    this.initialRoomTitle = '채팅방 제목',
    this.initialIsPublic = true,
  }) : super(key: key);

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late String _roomTitle;
  late bool _isPublic;

  // ─── 메시지 관련 필드 ───
  final List<ChatMessage> _messages = [];
  Timer? _pollTimer;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late Future<String> _futureNickname;
  bool _isLoading = false;

  // ─── 참가자 목록을 문자열 리스트로 관리 (final 제거) ───
  List<String> _participants = [];

  @override
  void initState() {
    super.initState();
    _roomTitle = widget.initialRoomTitle;
    _isPublic = widget.initialIsPublic;

    _futureNickname = LocalManager.getNickname();

    // 메시지 로드 + 주기적 폴링
    _loadMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _loadMessages());

    // 참가자 목록 로드
    _loadParticipants();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// ─── 1) 채팅 메시지 가져오기 ───
  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final fetched = await RunningChatService().fetchMessages(widget.roomId);
      setState(() {
        _messages
          ..clear()
          ..addAll(fetched);
      });
      _scrollToBottom();
    } catch (e) {
      print('[ChatRoomScreen] 메시지 불러오기 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ─── 2) 채팅 메시지 전송 ───
  Future<void> _sendMessage({required String text}) async {
    if (text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await RunningChatService().sendMessage(
        roomId: widget.roomId,
        message: text.trim(),
      );
      _textController.clear();

      final updated = await RunningChatService().fetchMessages(widget.roomId);
      setState(() {
        _messages
          ..clear()
          ..addAll(updated);
      });
      _scrollToBottom();
    } catch (e) {
      print('[ChatRoomScreen] 메시지 전송 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSend() async {
    final text = _textController.text;
    await _sendMessage(text: text);
  }

  /// ─── 3) 채팅 스크롤을 맨 아래로 이동 ───
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// ─── 4) 채팅방 참여자 목록 조회 ───
  Future<void> _loadParticipants() async {
    try {
      final nicknames = await RunningChatService().fetchParticipants(widget.roomId);
      setState(() {
        _participants = nicknames;
      });
    } on DioError catch (err) {
      if (err.response?.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('잘못된 요청입니다.')),
        );
      } else if (err.response?.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('채팅 참여자가 아닙니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('참가자 목록을 불러오는 데 실패했습니다.')),
        );
      }
    } catch (e) {
      print('[ChatRoomScreen] 참가자 목록 조회 중 예외: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('참가자 목록을 불러오는 데 오류가 발생했습니다.')),
      );
    }
  }

  /// ─── 5) 방 제목 수정 ───
  Future<void> _editRoomTitle() async {
    final controller = TextEditingController(text: _roomTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('방 제목 수정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '새 제목'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text?.trim()),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (newTitle != null && newTitle.isNotEmpty && newTitle != _roomTitle) {
      setState(() => _roomTitle = newTitle);
      await RunningChatService().updateRoomTitle(widget.roomId, newTitle);
    }
  }

  /// ─── 6) 공개/비공개 상태 토글 ───
  Future<void> _togglePublic() async {
    final newState = !_isPublic;
    setState(() => _isPublic = newState);
    await RunningChatService().updateRoomVisibility(widget.roomId, newState);
  }

  /// ─── 7) 채팅방 나가기 ───
  Future<void> _leaveRoomAndNavigate() async {
    try {
      await RunningChatService().leaveRoom(widget.roomId);
    } catch (_) {
      // 에러 무시
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MatchingListScreen()),
    );
  }

  Future<void> _confirmLeave() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('채팅방 나가기'),
        content: const Text('정말 채팅방에서 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('예'),
          ),
        ],
      ),
    );
    if (shouldLeave == true) {
      await _leaveRoomAndNavigate();
    }
  }

  /// ─── 8) 참가 요청 목록 다이얼로그 (기존과 동일) ───
  Future<void> _showJoinRequestsDialog() async {
    List<JoinRequest> joinRequests = [];
    try {
      joinRequests = await RunningChatService().getJoinRequests(widget.roomId);
    } catch (e) {
      print('[ChatRoomScreen] 참가 요청 목록 조회 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('참가 요청 목록을 불러오는 데 실패했습니다.')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        final List<JoinRequest> _localRequests = List.from(joinRequests);

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('참가 요청 목록'),
              content: SizedBox(
                width: double.maxFinite,
                child: _localRequests.isEmpty
                    ? const Center(child: Text('새 참가 요청이 없습니다.'))
                    : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _localRequests.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final req = _localRequests[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(req.requesterUsername.isNotEmpty
                            ? req.requesterUsername[0]
                            : '?'),
                      ),
                      title: Text(req.requesterUsername),
                      subtitle: Text(
                        '${req.requestedAt.month.toString().padLeft(2, '0')}-'
                            '${req.requestedAt.day.toString().padLeft(2, '0')} '
                            '${req.requestedAt.hour.toString().padLeft(2, '0')}:'
                            '${req.requestedAt.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () async {
                              try {
                                await RunningChatService()
                                    .acceptJoinRequest(req.requestId);
                                setStateDialog(() {
                                  _localRequests.removeAt(index);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${req.requesterUsername} 님 참가를 수락했습니다.'),
                                  ),
                                );
                              } catch (e) {
                                print('[ChatRoomScreen] 참가 요청 수락 실패: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('참가 요청 수락에 실패했습니다.')),
                                );
                              }
                            },
                            child: const Text(
                              '수락',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setStateDialog(() {
                                _localRequests.removeAt(index);
                              });
                            },
                            child: const Text(
                              '거절',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onAddPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이미지 첨부 기능은 지원되지 않습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F0F3),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _confirmLeave,
        ),
        title: GestureDetector(
          onTap: _editRoomTitle,
          child: Text(_roomTitle),
        ),
        actions: [
          IconButton(
            icon: Icon(_isPublic ? Icons.lock_open : Icons.lock),
            onPressed: _togglePublic,
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),

      // ─── 참여자 목록을 Dynamic하게 렌더 ───
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _participants.isEmpty
                    ? const Center(child: Text('참가자가 없습니다.'))
                    : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  itemCount: _participants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final nickname = _participants[index];
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          child: Text(
                            nickname.isNotEmpty ? nickname[0] : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFFBBBBBB),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          nickname,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ─── 참가 대기 버튼 ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                child: OutlinedButton(
                  onPressed: _showJoinRequestsDialog,
                  child: const Text('참가 대기'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCCCCCC)),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              // ─── 러닝하기 버튼 ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RunningScreen(roomId: widget.roomId),
                      ),
                    );
                  },
                  child: const Text('러닝하기'),
                  style: ElevatedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCCCCCC)),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              // ─── 채팅방 나가기 버튼 ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: OutlinedButton(
                  onPressed: _confirmLeave,
                  child: const Text('채팅방 나가기'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCCCCCC)),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ─── 채팅 본문 ───
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<String>(
              future: _futureNickname,
              builder: (context, snapshot) {
                final myNick = snapshot.data ?? '';
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg = _messages[i];
                    final isMe = msg.sender == myNick;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFE1B08C) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  msg.sender,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            Text(msg.message),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 입력창
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: ChatBox(
                    controller: _textController,
                    onSend: _handleSend,
                    //onAdd: _onAddPressed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
