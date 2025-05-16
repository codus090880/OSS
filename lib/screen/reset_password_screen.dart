import 'dart:async';
import 'package:flutter/material.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/grey_box.dart';
import 'package:prunners/widget/button_box.dart';
import 'package:prunners/screen/login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  int step = 1;
  int remainingSeconds = 300;
  Timer? timer;

  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  void startTimer() {
    timer?.cancel();
    remainingSeconds = 300;

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          t.cancel();
        }
      });
    });
  }

  void onNextStep() {
    if (step == 1) {
      // 이메일 유효성 검사 및 인증 요청
      startTimer();
      setState(() => step = 2);
    } else if (step == 2) {
      if (codeController.text == "123456") {
        setState(() => step = 3);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("인증번호가 올바르지 않습니다.")),
        );
      }
    } else if (step == 3) {
      if (passwordController.text != confirmController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("비밀번호가 일치하지 않습니다.")),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("비밀번호가 성공적으로 변경되었습니다.")),
      );

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomTopBar(title: '비밀번호 변경'),
            SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (step >= 1) ...[
                    GreyBox(
                      child: TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          hintText: '가입하신 이메일을 입력해주세요',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 17),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (step >= 2) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('인증번호 입력'),
                        Text(
                          formatTime(remainingSeconds),
                          style: TextStyle(
                            color: remainingSeconds > 0 ? Colors.black : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GreyBox(
                      child: TextField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          hintText: '인증번호를 입력해주세요',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 17),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (step >= 3) ...[
                    GreyBox(
                      child: TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: '새로운 비밀번호를 입력해주세요',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 17),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GreyBox(
                      child: TextField(
                        controller: confirmController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: '비밀번호 재확인',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 17),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 30),
                  ButtonBox(
                    onPressed: onNextStep,
                    text: step == 1
                        ? '인증번호 요청'
                        : step == 2
                        ? '인증번호 확인'
                        : '비밀번호 재설정',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
