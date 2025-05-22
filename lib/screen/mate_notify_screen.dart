import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/outlined_button_box.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/model/local_manager.dart';

class MateNotifyScreen extends StatefulWidget {
  const MateNotifyScreen({super.key});

  @override
  State<MateNotifyScreen> createState() => _MateNotifyScreenState();
}

class _MateNotifyScreenState extends State<MateNotifyScreen> {
  final TextEditingController notifyController = TextEditingController();

  // mockData
  final String targetName = '홍길동';
  final sessionId = 123;

  Future<void> submitNotify() async {
    final String notifyText = notifyController.text.trim();
    if(notifyText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신고 내용을 입력해주세요')),
      );
      return;
    }
    final dio = Dio();
    try {
      final reporter = await LocalManager.getNickname();
      final response = await dio.post(
        'http://127.0.0.1:8000/mate_notify/',
        data: {
          'reporter': reporter,
          'target': targetName,
          'session_id': sessionId,
          'content': notifyText,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
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
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
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
                  decoration: InputDecoration(
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
