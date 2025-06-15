import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/chat_box.dart';
import 'package:prunners/model/chat_service.dart';
import 'package:prunners/model/auth_service.dart';

import '../model/local_manager.dart';

/// 채팅 화면
class ChatScreen extends StatefulWidget {
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
  Timer? _pollTimer;

  // 내 닉네임 조회 (로컬 스토리지에서 가져올 때 사용)
  Future<String> get _myNickname => LocalManager.getNickname();

  @override
  void initState() {
    super.initState();
    _initializeChat();

    // 3초마다 메시지 자동 갱신
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_roomId == null) return;
      try {
        final updated = await ChatService().fetchMessages(_roomId!);
        setState(() {
          _messages
            ..clear()
            ..addAll(updated);
        });
        _scrollToBottom();
      } catch (e) {
        print('[ChatScreen] 자동 갱신 실패: $e');
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 1) 친구 채팅방 조회 또는 생성 → roomId 저장 → 초기 메시지 로드
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

  /// 2) 보내기 버튼 눌렀을 때: 텍스트와(또는)이미지 전송
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

  /// 3) 카메라/갤러리 권한 요청
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [Permission.camera, Permission.storage].request();
      return statuses.values.every((s) => s.isGranted);
    } else {
      final statuses = await [Permission.camera, Permission.photos].request();
      return statuses.values.every((s) => s.isGranted);
    }
  }

  /// 4) 이미지 선택용 바텀 시트
  Future<void> _showImageSourceActionSheet() async {
    if (!await _requestPermissions()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('권한이 필요합니다. 설정에서 허용해주세요.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('갤러리'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('카메라'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
        ]),
      ),
    );
  }

  /// 5) 실제로 이미지 파일 선택
  Future<void> _pickImage(ImageSource src) async {
    final XFile? picked = await _picker.pickImage(source: src);
    if (picked == null) return;
    setState(() => _selectedImageFile = File(picked.path));
  }

  /// 6) 채팅 화면에서 스크롤을 맨 아래로 이동
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F3),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: CustomTopBar(
          titleWidget: Row(
            children: [
              // 1) 프로필 이미지가 비어 있을 때 기본 아이콘 표시
              CircleAvatar(
                radius: 16,
                backgroundImage: widget.friendAvatarUrl.isNotEmpty
                    ? NetworkImage(widget.friendAvatarUrl)
                    : null,
                child: widget.friendAvatarUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(widget.friendUsername),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 로딩 중이고 메시지가 비어 있을 때만 전체 로딩 인디케이터 표시
              if (_isLoading && _messages.isEmpty)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: FutureBuilder<String>(
                    future: _myNickname,
                    builder: (context, snapshot) {
                      final myNick = snapshot.data ?? '';
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          final isMe = msg.sender == myNick;
                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: msg.imageUrl != null && msg.imageUrl!.isNotEmpty
                                  ? EdgeInsets.zero
                                  : const EdgeInsets.all(12),
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
                                  // 보낸 사람 닉네임 (내가 아닌 경우에만)
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
                                  // 2) 이미지가 있을 때만 Image.network 호출
                                  if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        msg.imageUrl!,
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image),
                                      ),
                                    ),
                                  // 3) 텍스트 메시지가 있을 때만 텍스트 표시
                                  if (msg.message.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(
                                          top: (msg.imageUrl != null && msg.imageUrl!.isNotEmpty) ? 4 : 0
                                      ),
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

              // 입력창(텍스트 + 이미지 첨부 버튼)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

          // 메시지가 이미 로드되어 있고, 추가 전송/갱신 중일 때 상단에 작은 인디케이터 표시
          if (_isLoading && _messages.isNotEmpty)
            const Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
