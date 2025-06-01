import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'package:prunners/model/auth_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;

  late final IOWebSocketChannel _channel;
  late final StreamController<ChatMessage> _controller;
  final _uuid = Uuid();

  ChatService._internal() {
    _controller = StreamController<ChatMessage>.broadcast();

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

  void sendMessage({
    required String roomId,
    required String email,
    required String nickname,
    String? text,
    String? imagePath,
  }) {
    final msg = ChatMessage(
      id: _uuid.v4(),
      roomId: roomId,
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

extension RoomManagement on ChatService {
  /// 방 제목을 서버에 업데이트
  Future<void> updateRoomTitle(String roomId, String newTitle) async {
    try {
      await AuthService.dio.put(
        '/rooms/$roomId/title',
        data: {'title': newTitle},
      );
      print('[RoomManagement] 방 제목 업데이트 성공');
    } on DioError catch (err) {
      print('[RoomManagement] 방 제목 업데이트 실패: ${err.response?.statusCode} ${err.message}');
    }
  }

  /// 방 공개 상태를 서버에 업데이트
  Future<void> updateRoomVisibility(String roomId, bool isPublic) async {
    try {
      await AuthService.dio.put(
        '/rooms/$roomId/visibility',
        data: {'isPublic': isPublic},
      );
      print('[RoomManagement] 공개 상태 업데이트 성공');
    } on DioError catch (err) {
      print('[RoomManagement] 공개 상태 업데이트 실패: ${err.response?.statusCode} ${err.message}');
    }
  }
}

class ChatMessage {
  final String id;
  final String roomId;
  final String email;
  final String nickname;
  final String? text;
  final String? imagePath;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.email,
    required this.nickname,
    this.text,
    this.imagePath,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      text: json['text'] as String?,
      imagePath: json['imagePath'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'email': email,
    'nickname': nickname,
    'text': text,
    'imagePath': imagePath,
    'timestamp': timestamp.toIso8601String(),
  };

  bool get hasImage => imagePath != null;
}

