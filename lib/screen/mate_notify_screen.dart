import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/outlined_button_box.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/model/local_manager.dart';
import 'package:prunners/model/auth_service.dart';

class MateNotifyScreen extends StatefulWidget {
  final String targetNickname;
  final int roomid;

  const MateNotifyScreen({
    super.key,
    required this.targetNickname,
    required this.roomid,
  });

  @override
  State<MateNotifyScreen> createState() => _MateNotifyScreenState();
}

class _MateNotifyScreenState extends State<MateNotifyScreen> {
  final TextEditingController notifyController = TextEditingController();

  Future<void> submitNotify() async {
    debugPrint('────────────────────────────────────────────');
    debugPrint('📌 신고 제출 함수 진입: /mate_notify/');
    debugPrint('  - 신고 대상: ${widget.targetNickname}');
    debugPrint('  - 방 ID: ${widget.roomid}');
    debugPrint('────────────────────────────────────────────');

    final String notifyText = notifyController.text.trim();
    if (notifyText.isEmpty) {
      debugPrint('⚠️ 신고 내용이 비어 있음');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신고 내용을 입력해주세요')),
      );
      return;
    }

    try {
      final reporter = await LocalManager.getNickname();
      debugPrint('✅ 신고자 닉네임 가져옴: $reporter');

      final body = {
        'reporter': reporter,
        'target': widget.targetNickname,
        'room_id': widget.roomid,
        'content': notifyText,
      };
      debugPrint('📤 요청 바디: $body');

      final response = await AuthService.dio.post<Map<String, dynamic>>(
        '/mate_notify/',
        data: body,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      debugPrint('✅ 응답 수신 완료');
      debugPrint('  → status: ${response.statusCode}');
      debugPrint('  → body  : ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고가 정상적으로 접수되었습니다')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('신고 실패: ${response.statusCode}')),
        );
      }
    } on DioError catch (err) {
      debugPrint('❌ DioError 발생');
      debugPrint('  .type           : ${err.type}');
      debugPrint('  .message        : ${err.message}');
      debugPrint('  .statusCode     : ${err.response?.statusCode}');
      debugPrint('  .response.data  : ${err.response?.data}');
      debugPrint('  .request.uri    : ${err.requestOptions.uri}');
      debugPrint('  .headers        : ${err.requestOptions.headers}');

      String userMsg = '신고 중 오류가 발생했습니다.';
      if (err.response?.statusCode == 400) {
        userMsg = '400: 요청 형식 오류 또는 필수값 누락';
      } else if (err.response?.statusCode == 403) {
        userMsg = '403: 권한이 없습니다.';
      } else if (err.response?.statusCode == 500) {
        userMsg = '500: 서버 오류가 발생했습니다.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userMsg)),
      );
    } catch (e, stack) {
      debugPrint('❗ 예외 발생');
      debugPrint('  .error: $e');
      debugPrint('  .stack: $stack');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }

    debugPrint('📤 신고 제출 함수 종료');
    debugPrint('────────────────────────────────────────────');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: CustomTopBar(title: '신고하기'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                '어떤 점이 문제가 되었나요?',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              const Text(
                '신고 내용은 관리자 확인 후 처리됩니다.',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              Container(
                height: 150,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: TextField(
                  controller: notifyController,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: '러닝 메이트에 대한 신고 사유를 자세하게 설명해주세요.',
                    hintStyle: TextStyle(fontSize: 15, color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              OutlinedButtonBox(
                text: '신고하기',
                onPressed: submitNotify,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(
          currentIndex: 2,
          onTap: (index) {
            if (index == 2) return;
            Navigator.pushReplacementNamed(
              context,
              ['/home', '/running', '/course', '/profile'][index],
            );
          },
        ),
      ),
    );
  }
}
