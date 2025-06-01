import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/chat_box.dart';
import 'package:prunners/model/chat_service.dart';
import 'package:prunners/model/local_manager.dart';
import 'package:prunners/screen/running_screen.dart';
import 'package:prunners/screen/matching_list_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  // 내 정보
  final String currentUserEmail;
  final String currentUserNickname;

  // 방 정보
  final int roomId;
  final String initialRoomTitle;
  final bool initialIsPublic;

  const ChatRoomScreen({
    Key? key,
    this.currentUserEmail = 'user@example.com',
    this.currentUserNickname = 'Me',
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
  final List<ChatMessage> _messages = [];
  Timer? _pollTimer;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  // 예시 참가자 리스트 (실제는 서버 API 호출로 대체)
  final List<Map<String, String>> _participants = [
    {'avatarUrl': 'https://via.placeholder.com/50', 'nickname': 'Alice'},
    {'avatarUrl': 'https://via.placeholder.com/50', 'nickname': 'Bob'},
    {'avatarUrl': 'https://via.placeholder.com/50', 'nickname': 'Charlie'},
  ];

  File? _selectedImageFile;
  bool _isLoading = false;

  Future<String> get _myNickname async {
    return await LocalManager.getNickname();
  }

  @override
  void initState() {
    super.initState();
    _roomTitle = widget.initialRoomTitle;
    _isPublic = widget.initialIsPublic;

    // 초기 메시지 불러오기
    _loadMessages();

    // 주기적으로 메시지 폴링 (예: 3초마다)
    _pollTimer = Timer.periodic(Duration(seconds: 3), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final fetched = await ChatService().fetchMessages(widget.roomId);
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

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [Permission.camera, Permission.storage].request();
      return statuses.values.every((s) => s.isGranted);
    } else {
      final statuses = await [Permission.camera, Permission.photos].request();
      return statuses.values.every((s) => s.isGranted);
    }
  }

  Future<void> _showImageSourceActionSheet() async {
    if (!await _requestPermissions()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('권한이 필요합니다. 설정에서 허용해주세요.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('갤러리'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('카메라'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _pickImage(ImageSource src) async {
    final XFile? picked = await _picker.pickImage(source: src);
    if (picked == null) return;
    setState(() => _selectedImageFile = File(picked.path));

    // 선택한 이미지 즉시 전송
    await _sendMessage(imageFile: _selectedImageFile);
  }

  Future<void> _sendMessage({String? text, File? imageFile}) async {
    if ((text == null || text.trim().isEmpty) && imageFile == null) return;

    setState(() => _isLoading = true);
    try {
      await ChatService().sendMessageHttp(
        roomId: widget.roomId,
        message: (text == null || text.trim().isEmpty) ? null : text.trim(),
        imageFile: imageFile,
      );
      _textController.clear();
      setState(() => _selectedImageFile = null);

      final updated = await ChatService().fetchMessages(widget.roomId);
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _editRoomTitle() async {
    final controller = TextEditingController(text: _roomTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('방 제목 수정'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: '새 제목'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text?.trim()), child: Text('확인')),
        ],
      ),
    );
    if (newTitle != null && newTitle.isNotEmpty && newTitle != _roomTitle) {
      setState(() => _roomTitle = newTitle);
      await ChatService().updateRoomTitle(widget.roomId, newTitle);
    }
  }

  Future<void> _togglePublic() async {
    final newState = !_isPublic;
    setState(() => _isPublic = newState);
    await ChatService().updateRoomVisibility(widget.roomId, newState);
  }

  Future<void> _leaveRoomAndNavigate() async {
    try {
      await ChatService().leaveRoom(widget.roomId);
    } catch (_) {
      // 에러 무시
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MatchingListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFF0F0F3),
      appBar: AppBar(
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
            icon: Icon(Icons.menu), // 샌드위치 메뉴
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              // 1. 참가자 리스트
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  itemCount: _participants.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final p = _participants[index];
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(p['avatarUrl']!),
                        ),
                        SizedBox(width: 12),
                        Text(
                          p['nickname']!,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // 2. 러닝하기 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RunningScreen()),
                    );
                  },
                  child: Text('러닝하기'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              SizedBox(height: 12),

              // 3. 채팅방 나가기 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: OutlinedButton(
                  onPressed: _leaveRoomAndNavigate,
                  child: Text('채팅방 나가기'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // 채팅 메시지 영역
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                return FutureBuilder<String>(
                  future: _myNickname,
                  builder: (context, snapshot) {
                    final myNick = snapshot.data ?? '';
                    final isMe = msg.sender == myNick;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        padding: msg.imageUrl != null ? EdgeInsets.zero : EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Color(0xFFE1B08C) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text(
                                  msg.sender,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            if (msg.imageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  msg.imageUrl!,
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(Icons.broken_image),
                                ),
                              ),
                            if (msg.message.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: msg.imageUrl != null ? 4 : 0),
                                child: Text(msg.message),
                              ),
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
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: ChatBox(
                    controller: _textController,
                    onSend: _handleSend,
                    onAdd: _showImageSourceActionSheet,
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
