// model/chat_service.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:prunners/model/auth_service.dart';

class ChatMessage {
  final String sender;    // 서버가 내려주는 'sender' (닉네임 혹은 이메일)
  final String message;   // 텍스트
  final String? imageUrl; // 이미지 URL (없으면 null)

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

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;

  final Dio _dio = AuthService.dio;

  ChatService._internal();

  /// 1) 방 조회/생성 (GET /friend-chat/<friend_username>/)
  Future<int> getOrCreateRoom(String friendUsername) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/friend-chat/$friendUsername/',
      );
      final roomId = response.data?['room_id'] as int;
      return roomId;
    } on DioError catch (err) {
      print('[ChatService] getOrCreateRoom 실패: '
          '${err.response?.statusCode} ${err.message}');
      rethrow;
    }
  }

  /// 2) 메시지 목록 가져오기 (GET /friend-chat/messages/<room_id>/)
  Future<List<ChatMessage>> fetchMessages(int roomId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/friend-chat/messages/$roomId/',
      );
      final data = response.data;
      if (data == null) return [];
      return data
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioError catch (err) {
      print('[ChatService] fetchMessages 실패: '
          '${err.response?.statusCode} ${err.message}');
      return [];
    }
  }

  /// 3) 메시지 전송 (POST multipart/form-data to /friend-chat/messages/<room_id>/)
  ///    - 이제 'sender'나 'email'을 붙이지 않고, 서버가 헤더(JWT)에서 알아서 처리한다고 가정
  Future<void> sendMessageHttp({
    required int roomId,
    String? message,
    File? imageFile,
  }) async {
    try {
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

      final response = await _dio.post<Map<String, dynamic>>(
        '/friend-chat/messages/$roomId/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      print('[ChatService] sendMessageHttp 성공: '
          '${response.data?['message_id']}');
    } on DioError catch (err) {
      print('[ChatService] sendMessageHttp 실패: '
          '${err.response?.statusCode} ${err.message}');
      rethrow;
    }
  }

  /// 4) 방 나가기 (DELETE /friend-chat/<room_id>/leave/)
  Future<void> leaveRoom(int roomId) async {
    try {
      await _dio.delete('/friend-chat/$roomId/leave/');
      print('[ChatService] leaveRoom 성공: $roomId');
    } on DioError catch (err) {
      print('[ChatService] leaveRoom 실패: ${err.message}');
      rethrow;
    }
  }
}

// ────────────────────────────────────────────────────────────
// 여기서부터 RoomManagement extension 추가
// ────────────────────────────────────────────────────────────

extension RoomManagement on ChatService {
  /// 방 제목을 수정 (PUT /rooms/<room_id>/title/)
  Future<void> updateRoomTitle(int roomId, String newTitle) async {
    try {
      await AuthService.dio.put(
        '/rooms/$roomId/title/',
        data: {'title': newTitle},
      );
      print('[RoomManagement] 방 제목 업데이트 성공');
    } on DioError catch (err) {
      print('[RoomManagement] 방 제목 업데이트 실패: ${err.message}');
    }
  }

  /// 방 공개 상태를 수정 (PUT /rooms/<room_id>/visibility/)
  Future<void> updateRoomVisibility(int roomId, bool isPublic) async {
    try {
      await AuthService.dio.put(
        '/rooms/$roomId/visibility/',
        data: {'isPublic': isPublic},
      );
      print('[RoomManagement] 공개 상태 업데이트 성공');
    } on DioError catch (err) {
      print('[RoomManagement] 공개 상태 업데이트 실패: ${err.message}');
    }
  }
}
