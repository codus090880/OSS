import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:prunners/widget/rounded_shadow_box.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/outlined_button_box.dart';
import 'package:prunners/model/auth_service.dart';
import 'package:prunners/screen/running_chat_screen.dart';

class ChatDetailScreen extends StatelessWidget {
  final int roomId;

  const ChatDetailScreen({
    super.key,
    required this.roomId,
  });

  /// ─── 서버에서 유저 정보 가져오기 ───
  /// EndPoint: POST /chatroom_users/
  /// Request Body: { "room_id": int }
  /// Success Response: 200 OK + 유저 정보 배열
  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final resp = await AuthService.dio.post<List<dynamic>>(
      '/chatroom_users/',
      data: {'room_id': roomId},
    );
    final List<dynamic> data = resp.data ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(title: '러닝 메이트 정보'),
      ),
      body: Column(
        children: [
          // ─── 1) 서버에서 유저 정보를 로드하여 리스트로 보여주는 부분 ───
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '유저 정보를 불러오는 중 오류가 발생했습니다.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                final users = snapshot.data ?? [];

                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      '참여자가 없습니다.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final username = user['username'] as String? ?? '';
                    final gender = user['gender'] as String? ?? '';
                    final temp = (user['temperature'] as num?)?.toDouble() ?? 0.0;
                    final level = user['grade_level'] as String? ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── 프로필 아이콘 + 이름/성별 ───
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.account_circle,
                                size: 60,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    username,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    gender,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // ─── 매너 온도 & 레벨 ───
                          Row(
                            children: [
                              Expanded(
                                child: RoundedShadowBox(
                                  height: 80,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '매너 온도',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                          letterSpacing: 0.16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.device_thermostat,
                                            size: 34,
                                            color: Colors.black,
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            '${temp.toStringAsFixed(1)} °C',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                              letterSpacing: 0.20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: RoundedShadowBox(
                                  height: 80,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '레벨',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                          letterSpacing: 0.16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.leaderboard,
                                            size: 34,
                                            color: Colors.black,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              level,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                                letterSpacing: 0.20,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ─── 2) “참여하기” 버튼: join-request 전에 /chatrooms/my/ 체크 ───
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: OutlinedButtonBox(
                text: '참여하기',
                onPressed: () async {
                  int? myRoomId;
                  try {
                    final myResp = await AuthService.dio.get<List<dynamic>>(
                      '/chatrooms/my/',
                    );

                    // 디버깅: statusCode 및 raw data
                    debugPrint('[/chatrooms/my/] 성공: statusCode=${myResp.statusCode}');
                    debugPrint('[/chatrooms/my/] raw data=${myResp.data}');

                    final List<dynamic> dataList = myResp.data ?? [];

                    if (dataList.isNotEmpty) {
                      // 각 요소를 Map<String, dynamic>으로 간주하여 room_id 목록 생성
                      final ids = dataList
                          .whereType<Map<String, dynamic>>()
                          .map((e) => e['room_id'] as int)
                          .toList();
                      debugPrint('추출된 room_id들: $ids');

                      // 현재 roomId와 일치하는 값이 있는지 확인
                      if (ids.contains(roomId)) {
                        myRoomId = roomId;
                        debugPrint('roomId=$roomId 과 일치하는 방이 있으므로 myRoomId=$myRoomId 로 설정');
                      } else {
                        myRoomId = null;
                        debugPrint('roomId=$roomId 과 일치하는 방이 없습니다.');
                      }
                    } else {
                      myRoomId = null;
                      debugPrint('[/chatrooms/my/] 데이터가 비어 있습니다.');
                    }
                  } on DioError catch (err) {
                    debugPrint('=== DioError 발생 (/chatrooms/my/) ===');
                    debugPrint('  .type           : ${err.type}');
                    debugPrint('  .message        : ${err.message}');
                    debugPrint('  .error          : ${err.error}');
                    debugPrint('  .statusCode     : ${err.response?.statusCode}');
                    debugPrint('  .response data  : ${err.response?.data}');
                    debugPrint('  .requestOptions.uri    : ${err.requestOptions.uri}');
                    debugPrint('  .requestOptions.method : ${err.requestOptions.method}');
                    debugPrint('  .requestOptions.headers: ${err.requestOptions.headers}');
                    myRoomId = null;
                  } catch (e) {
                    debugPrint('=== 예외 발생 (/chatrooms/my/) ===');
                    debugPrint('  error: $e');
                    myRoomId = null;
                  }

                  // 디버깅: myRoomId와 현재 roomId 비교
                  debugPrint('myRoomId = $myRoomId, current roomId = $roomId');

                  // ─── 2) 이미 같은 방에 참여 중이라면 ChatRoomScreen으로 이동 ───
                  if (myRoomId != null && myRoomId == roomId) {
                    debugPrint('이미 참여 중인 방입니다. ChatRoomScreen으로 이동합니다.');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(roomId: roomId),
                      ),
                    );
                    return;
                  } else {
                    debugPrint('아직 참여하지 않았거나 roomId가 일치하지 않습니다.');
                  }

                  // ─── 3) 참가 요청 ───
                  try {
                    final joinResp = await AuthService.dio.post<Map<String, dynamic>>(
                      '/chatroom/$roomId/join-request/',
                    );
                    debugPrint(
                        'Join-request 성공: status=${joinResp.statusCode}, data=${joinResp.data}');
                    final message =
                        joinResp.data?['message'] as String? ?? '참가 요청 완료';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  } on DioError catch (err) {
                    debugPrint('=== DioError 발생 (/chatroom/$roomId/join-request/) ===');
                    debugPrint('  .type           : ${err.type}');
                    debugPrint('  .message        : ${err.message}');
                    debugPrint('  .error          : ${err.error}');
                    debugPrint('  .statusCode     : ${err.response?.statusCode}');
                    debugPrint('  .response data  : ${err.response?.data}');
                    debugPrint('  .requestOptions.uri    : ${err.requestOptions.uri}');
                    debugPrint('  .requestOptions.method : ${err.requestOptions.method}');
                    debugPrint('  .requestOptions.headers: ${err.requestOptions.headers}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('참가 요청 중 오류가 발생했습니다.')),
                    );
                  } catch (e) {
                    debugPrint(
                        '=== 예외 발생 (/chatroom/$roomId/join-request/) ===\n  error: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('알 수 없는 오류가 발생했습니다.')),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
