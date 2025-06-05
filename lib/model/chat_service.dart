import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:prunners/model/auth_service.dart';

/// 채팅 메시지 모델
class ChatMessage {
  final String sender;    // 서버가 내려주는 'sender' 필드
  final String message;   // 서버가 내려주는 'message' 필드
  final String? imageUrl; // 서버가 내려주는 'image_url' 필드 (optional)

  ChatMessage({
    required this.sender,
    required this.message,
    this.imageUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['sender'] as String,
      message: json['message'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }
}

/// 채팅 서비스 (singleton)
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;

  final Dio _dio = AuthService.dio; // JWT 인터셉터 적용된 Dio

  ChatService._internal();

  /// 1) 방 조회/생성
  ///    GET  /friend-chat/<friend_username>/
  ///    Response: { "room_id": int }
  Future<int> getOrCreateRoom(String friendUsername) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/friend-chat/$friendUsername/',
      );
      final roomId = response.data?['room_id'] as int;
      return roomId;
    } on DioError catch (err) {
      print('[ChatService] getOrCreateRoom 실패: '
          'status=${err.response?.statusCode}, data=${err.response?.data}');
      rethrow;
    }
  }

  /// 2) 메시지 조회
  ///    GET  /friend-chat/messages/<room_id>/
  ///    Response: List< { "sender": str, "message": str, "image_url": str|null } >
  Future<List<ChatMessage>> fetchMessages(int roomId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/friend-chat/messages/$roomId/',
      );
      final data = response.data;
      if (data == null) return [];
      return data
          .cast<Map<String, dynamic>>()
          .map((json) => ChatMessage.fromJson(json))
          .toList();
    } on DioError catch (err) {
      print('[ChatService] fetchMessages 실패: '
          'status=${err.response?.statusCode}, data=${err.response?.data}');
      return [];
    }
  }

  /// 3) 메시지 전송
  ///    POST multipart/form-data to /friend-chat/send_messages/<room_id>/
  ///
  ///    Request Body 필드:
  ///      - room_id : int (필수)
  ///      - message : String (optional)
  ///      - image   : File   (optional)
  ///
  ///    Success Response: { "message": "전송 완료", "message_id": int }
  Future<void> sendMessageHttp({
    required int roomId,
    String? message,
    File? imageFile,
  }) async {
    // roomId는 URL path에서 이미 처리하기 때문에, body에도 "room_id" 필드를 반드시 추가해 달라는 스펙에 맞춥니다.
    final formData = FormData();
    formData.fields.add(MapEntry('room_id', roomId.toString()));

    if (message != null && message.trim().isNotEmpty) {
      formData.fields.add(MapEntry('message', message.trim()));
    }

    if (imageFile != null) {
      final fileName = path.basename(imageFile.path);
      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(
            imageFile.path,
            filename: fileName,
          ),
        ),
      );
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/friend-chat/send_messages/$roomId/',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      print('[ChatService] sendMessageHttp 성공: '
          'message_id=${response.data?['message_id']}');
    } on DioError catch (err) {
      print('[ChatService] sendMessageHttp 실패: '
          'status=${err.response?.statusCode}, data=${err.response?.data}');
      rethrow;
    }
  }
}
