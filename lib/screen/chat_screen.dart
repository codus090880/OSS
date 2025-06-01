import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/chat_box.dart';
import 'package:prunners/model/chat_service.dart';
import 'package:prunners/model/auth_service.dart';

class ChatScreen extends StatefulWidget {
  // 친구의 ID(서버 API 호출용) 이자, UI에 표시할 닉네임
  final String friendUsername;
  final String friendAvatarUrl;

  const ChatScreen({
    Key? key,
    required this.friendUsername,
    required this.friendAvatarUrl,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int? _roomId;
  final List<ChatMessage> _messages = [];

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImageFile;
  bool _isLoading = false;

  // 예: 로컬 스토리지나 JWT payload에서 내 닉네임을 가져오는 메서드
  Future<String> get _myNickname async {
    final stored = await AuthService.storage.read(key: 'MY_NICKNAME');
    return stored ?? '';
  }

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    try {
      final roomId =
      await ChatService().getOrCreateRoom(widget.friendUsername);
      setState(() => _roomId = roomId);

      final msgs = await ChatService().fetchMessages(roomId);
      setState(() {
        _messages
          ..clear()
          ..addAll(msgs);
      });
      _scrollToBottom();
    } catch (e) {
      print('[ChatScreen] _initializeChat 에러: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if ((text.isEmpty) && _selectedImageFile == null) return;
    if (_roomId == null) return;

    setState(() => _isLoading = true);
    try {
      await ChatService().sendMessageHttp(
        roomId: _roomId!,
        message: text.isEmpty ? null : text,
        imageFile: _selectedImageFile,
      );
      _textController.clear();
      setState(() => _selectedImageFile = null);

      final updated = await ChatService().fetchMessages(_roomId!);
      setState(() {
        _messages
          ..clear()
          ..addAll(updated);
      });
      _scrollToBottom();
    } catch (e) {
      print('[ChatScreen] _handleSend 에러: $e');
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
              Text(widget.friendUsername),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_isLoading && _messages.isEmpty)
                Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: FutureBuilder<String>(
                    future: _myNickname,
                    builder: (context, snapshot) {
                      final myNick = snapshot.data ?? '';
                      return ListView.builder(
                        controller: _scrollController,
                        padding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          final isMe = msg.sender == myNick;
                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              padding: msg.imageUrl != null
                                  ? EdgeInsets.zero
                                  : EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                isMe ? Color(0xFFE1B08C) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
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
                                      padding: EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        msg.sender,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
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
                                        errorBuilder: (_, __, ___) =>
                                            Icon(Icons.broken_image),
                                      ),
                                    ),
                                  if (msg.message.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(
                                          top: msg.imageUrl != null
                                              ? 4
                                              : 0),
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
          if (_isLoading && _messages.isNotEmpty)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child:
                SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
        ],
      ),
    );
  }
}
