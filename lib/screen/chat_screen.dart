import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/chat_box.dart';

/// 메시지 모델
class ChatMessage {
  final String id;
  final String userId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.text,
    required this.timestamp,
  });
}

/// Mock 채팅 서비스: 앱 내에서 메시지 송수신 테스트
class MockChatService {
  static final MockChatService _instance = MockChatService._internal();
  factory MockChatService() => _instance;
  MockChatService._internal() {
    _controller = StreamController<ChatMessage>.broadcast();
  }

  late final StreamController<ChatMessage> _controller;
  Stream<ChatMessage> get messages => _controller.stream;

  final _uuid = Uuid();
  final _botUserId = 'bot';


  void sendMessage(String text, String fromUser) {
    final msg = ChatMessage(
      id: _uuid.v4(),
      userId: fromUser,
      text: text,
      timestamp: DateTime.now(),
    );
    _controller.add(msg);

    // 봇 답장 (2초 뒤)
    Future.delayed(Duration(seconds: 2), () {
      final reply = ChatMessage(
        id: _uuid.v4(),
        userId: _botUserId,
        text: 'Echo: $text',
        timestamp: DateTime.now(),
      );
      _controller.add(reply);
    });
  }
}

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String title;
  const ChatScreen({
    Key? key,
    this.currentUserId = 'user1',
    this.title = '채팅 테스트',
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <ChatMessage>[];
  late final StreamSubscription<ChatMessage> _sub;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sub = MockChatService().messages.listen((msg) {
      setState(() {
        _messages.add(msg);
      });
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    MockChatService().sendMessage(text, widget.currentUserId);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F0F3),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(
          title: widget.title,
          rightIcon: Icons.menu,
          onRightPressed: () {},
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: false,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                final isMe = msg.userId == widget.currentUserId;
                return Align(
                  alignment:
                  isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Color(0xFFE1B08C)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(msg.text),
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
            child: ChatBox(
              controller: _textController,
              onSend: _handleSend,
            ),
          ),
        ],
      ),
    );
  }
}