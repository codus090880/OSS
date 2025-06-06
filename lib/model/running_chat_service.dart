import 'package:dio/dio.dart';
import 'package:prunners/model/auth_service.dart';


class ChatMessage {
  final String sender;
  final String message;
  final DateTime sentAt;

  ChatMessage({
    required this.sender,
    required this.message,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['sender'] as String,
      message: json['message'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
    );
  }
}

class RunningChatService {
  static final RunningChatService _instance = RunningChatService._internal();
  factory RunningChatService() => _instance;

  final Dio _dio = AuthService.dio;

  RunningChatService._internal();

  /// 1) 방 조회/생성 (GET /friend-chat/<friend_username>/)
  /*Future<int> getOrCreateRoom(String friendUsername) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/friend-chat/$friendUsername/',
      );
      final roomId = response.data?['room_id'] as int;
      return roomId;
    } on DioError catch (err) {
      print('[RunningChatService] getOrCreateRoom 실패: '
          '${err.response?.statusCode} ${err.message}');
      rethrow;
    }
  }*/

  /// 2) 메시지 목록 가져오기 (GET /chat/rooms/<room_id>/messages/)
  Future<List<ChatMessage>> fetchMessages(int roomId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/chat/rooms/$roomId/messages/',
      );
      final data = response.data;
      if (data == null) return [];
      return data
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioError catch (err) {
      print('[RunningChatService] fetchMessages 실패: '
          '${err.response?.statusCode} ${err.message}');
      return [];
    }
  }

  /// 3) 메시지 전송 (POST application/json to /chatroom/<room_id>/messages/send/)
  Future<void> sendMessage({
    required int roomId,
    required String message,
  }) async {
    try {
      final payload = {'message': message.trim()};
      final response = await _dio.post<Map<String, dynamic>>(
        '/chatroom/$roomId/messages/send/',
        data: payload,
        options: Options(contentType: Headers.jsonContentType),
      );
      print('[RunningChatService] sendMessage 성공: '
          '${response.data?['message']}');
    } on DioError catch (err) {
      print('[RunningChatService] sendMessage 실패: '
          '${err.response?.statusCode} ${err.message}');
      rethrow;
    }
  }

  /// 4) 방 나가기 (DELETE /friend-chat/<room_id>/leave/)
  Future<void> leaveRoom(int roomId) async {
    try {
      await _dio.delete('/rooms/$roomId/leave/');
      print('[RunningChatService] leaveRoom 성공: $roomId');
    } on DioError catch (err) {
      print('[RunningChatService] leaveRoom 실패: ${err.message}');
      rethrow;
    }
  }

  /// 참가 요청 목록 조회
  Future<List<JoinRequest>> getJoinRequests(int roomId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/chatroom/$roomId/join-requests/',
      );
      final data = response.data;
      if (data == null) return [];
      return data
          .map((item) => JoinRequest.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioError catch (err) {
      print('[RunningChatService] getJoinRequests 실패: ${err.response?.statusCode} ${err.message}');
      rethrow;
    }
  }

  /// 참가 요청 수락
  Future<void> acceptJoinRequest(int requestId) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/chatroom/join-request/$requestId/accept/',
      );
      print('[RunningChatService] acceptJoinRequest 성공: ${response.data?['message']}');
    } on DioError catch (err) {
      print('[RunningChatService] acceptJoinRequest 실패: ${err.response?.statusCode} ${err.message}');
      rethrow;
    }
  }

  /// 7) 참가자 목록 조회 (GET /rooms/<room_id>/user_list/)
  Future<List<String>> fetchParticipants(int roomId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/rooms/$roomId/user_list/',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data == null) return [];

        return data
            .whereType<Map<String, dynamic>>()
            .map((item) => item['nickname'] as String)
            .toList();
      } else {
        print('[RunningChatService] fetchParticipants 비정상 상태코드: '
            '${response.statusCode}');
        return [];
      }
    } on DioError catch (err) {
      print('[RunningChatService] fetchParticipants 실패: '
          '${err.response?.statusCode} ${err.message}');
      rethrow;
    }
  }
}

/// Room 관리 확장 (선택 사항: 방 제목·공개 상태 수정)
extension RoomManagement on RunningChatService {
  /// 방 제목 수정 (PUT /rooms/<room_id>/title/)
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

  /// 방 공개 상태 수정 (PUT /rooms/<room_id>/visibility/)
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

class JoinRequest {
  final int requestId;
  final int requesterId;
  final String requesterUsername;
  final DateTime requestedAt;

  JoinRequest({
    required this.requestId,
    required this.requesterId,
    required this.requesterUsername,
    required this.requestedAt,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      requestId: json['request_id'] as int,
      requesterId: json['requester_id'] as int,
      requesterUsername: json['requester_username'] as String,
      requestedAt: DateTime.parse(json['requested_at'] as String),
    );
  }
}