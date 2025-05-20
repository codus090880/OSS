import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/chat_box.dart';
import 'package:prunners/model/chat_service.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  // 내 정보
  final String currentUserEmail;
  final String currentUserNickname;

  // 상대 정보
  final String friendEmail;
  final String friendNickname;
  final String friendAvatarUrl;

  const ChatScreen({
    Key? key,
    /*required this.currentUserEmail,
    required this.currentUserNickname,
    required this.friendEmail,
    required this.friendNickname,
    required this.friendAvatarUrl,*/
    this.currentUserEmail = 'user1@example.com',
    this.currentUserNickname = 'User',
    this.friendEmail = 'bot@example.com',
    this.friendNickname = 'Echo Bot',
    this.friendAvatarUrl = 'https://via.placeholder.com/150',
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  late final StreamSubscription<ChatMessage> _sub;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // WebSocket 메시지 스트림 구독
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
    // TODO: 업로드 후 URL을 받아오세요
    final imageUrl = file.path; // 임시로 로컬 경로 사용

    ChatService().sendMessage(
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
      email: widget.currentUserEmail,
      nickname: widget.currentUserNickname,
      text: text,
    );
    _textController.clear();
    _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F0F3),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(
          titleWidget: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(widget.friendAvatarUrl),
              ),
              SizedBox(width: 8),
              Text(widget.friendNickname),
            ],
          ),
          rightIcon: Icons.more_horiz,
          onRightPressed: () {},
        ),
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
                  alignment:
                  isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    padding:
                    msg.hasImage ? EdgeInsets.zero : EdgeInsets.all(12),
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
                                ? Image.network(
                              msg.imagePath!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Icons.broken_image),
                            )
                                : Image.file(
                              File(msg.imagePath!),
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
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
