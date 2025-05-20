import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:uuid/uuid.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;

  late final IOWebSocketChannel _channel;
  late final StreamController<ChatMessage> _controller;
  final _uuid = Uuid();

  ChatService._internal() {
    _controller = StreamController<ChatMessage>.broadcast();

    // TODO: 실제 서버 WS URL로 변경 (예: wss://api.yourserver.com/ws/chat/)
    _channel = IOWebSocketChannel.connect('wss://echo.websocket.events');

    _channel.stream.listen(
          (data) {
        final Map<String, dynamic> jsonMap = jsonDecode(data as String);
        final msg = ChatMessage.fromJson(jsonMap);
        _controller.add(msg);
      },
      onError: (e) => print('[WS ERROR] $e'),
      onDone: () => print('[WS] connection closed'),
    );
  }

  Stream<ChatMessage> get messages => _controller.stream;

  /// 메시지를 보내려면 email(고유키) + nickname(보여줄 이름)를 함께 넘겨야 합니다.
  void sendMessage({
    required String email,
    required String nickname,
    String? text,
    String? imagePath, // 서버 업로드 후 URL
  }) {
    final msg = ChatMessage(
      id: _uuid.v4(),
      email: email,
      nickname: nickname,
      text: text,
      imagePath: imagePath,
      timestamp: DateTime.now(),
    );

    // 로컬에도 즉시 표시
    _controller.add(msg);
    // 서버로 JSON 전송
    _channel.sink.add(jsonEncode(msg.toJson()));
  }

  void dispose() {
    _channel.sink.close();
    _controller.close();
  }
}

class ChatMessage {
  final String id;
  final String email;
  final String nickname;
  final String? text;
  final String? imagePath;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.email,
    required this.nickname,
    this.text,
    this.imagePath,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      text: json['text'] as String?,
      imagePath: json['imagePath'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'nickname': nickname,
    'text': text,
    'imagePath': imagePath,
    'timestamp': timestamp.toIso8601String(),
  };

  bool get hasImage => imagePath != null;
}
