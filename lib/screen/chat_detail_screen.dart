import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/outlined_button_box.dart';
import 'package:prunners/model/auth_service.dart';
import 'package:prunners/screen/running_chat_screen.dart';

class ChatDetailScreen extends StatelessWidget {
  final int roomId; // 채팅방 ID

  const ChatDetailScreen({
    super.key,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(title: '러닝 메이트 정보'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '유저 정보는 서버에서 요청하여 나중에 표시됩니다.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                // 나중에 users를 서버에서 받아와 여기에 표시할 수 있도록 주석 처리해두었습니다.
              ],
            ),
          ),

          // ─── “참여하기” 버튼: join-request 전에 /chatrooms/my/ 체크 ───
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: OutlinedButtonBox(
                text: '참여하기',
                onPressed: () async {
                  try {
                    // 1) 내가 이미 참여 중인 방이 있는지 조회
                    final myResp = await AuthService.dio.get<Map<String, dynamic>>(
                      '/chatrooms/my/',
                    );
                    final myRoomId = myResp.data?['room_id'] as int?;

                    // 2) 이미 같은 방에 참여 중이라면 바로 채팅 화면으로 이동
                    if (myRoomId != null && myRoomId == roomId) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomScreen(
                            roomId: roomId,
                          ),
                        ),
                      );
                      return;
                    }

                    // 3) 아직 참여하지 않은 방이라면 참가 요청
                    final joinResp = await AuthService.dio.post<Map<String, dynamic>>(
                      '/chatroom/$roomId/join-request/',
                    );
                    final message =
                        joinResp.data?['message'] as String? ?? '참가 요청 완료';

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  } on DioError catch (err) {
                    if (err.response?.statusCode == 400) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('이미 참가 요청을 보냈습니다.')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('참가 요청 중 오류가 발생했습니다.')),
                      );
                    }
                  } catch (e) {
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
