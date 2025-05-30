import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prunners/model/chat_service.dart';
import 'package:prunners/widget/chat_box.dart';

class ChatRoomScreen extends StatefulWidget {
  // 내 정보
  final String currentUserEmail;
  final String currentUserNickname;

  // 방 정보
  final String roomId;
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
  late String _roomTitle;
  late bool _isPublic;
  final List<ChatMessage> _messages = [];
  late final StreamSubscription<ChatMessage> _sub;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _roomTitle = widget.initialRoomTitle;
    _isPublic = widget.initialIsPublic;

    _sub = ChatService().messages.listen((msg) {
      setState(() => _messages.add(msg));
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    final XFile? file = await _picker.pickImage(source: src);
    if (file == null) return;
    final imageUrl = file.path;

    ChatService().sendMessage(
      roomId: widget.roomId,
      email: widget.currentUserEmail,
      nickname: widget.currentUserNickname,
      imagePath: imageUrl,
    );
    _scrollToBottom();
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    ChatService().sendMessage(
      roomId: widget.roomId,
      email: widget.currentUserEmail,
      nickname: widget.currentUserNickname,
      text: text,
    );
    _textController.clear();
    _scrollToBottom();
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
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text('확인')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            icon: Icon(Icons.more_horiz),
            onPressed: () {
              // 추가 옵션
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                final isMe = msg.email == widget.currentUserEmail;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    padding: msg.hasImage ? EdgeInsets.zero : EdgeInsets.all(12),
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
                              msg.nickname,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        if (msg.hasImage)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: msg.imagePath!.startsWith('http')
                                ? Image.network(msg.imagePath!, width: 200, height: 200, fit: BoxFit.cover)
                                : Image.file(File(msg.imagePath!), width: 200, height: 200, fit: BoxFit.cover),
                          ),
                        if (msg.text != null) Text(msg.text!),
                        SizedBox(height: 4),
                        Text(
                          '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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


