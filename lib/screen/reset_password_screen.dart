import 'dart:async';
import 'package:flutter/material.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/grey_box.dart';
import 'package:prunners/widget/button_box.dart';
import 'package:prunners/screen/login_screen.dart';
import 'package:dio/dio.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  int step = 1;
  int remainingSeconds = 300;
  Timer? timer;
  final bool isMock = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  final _pwdReg = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$');
  final _emailReg = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

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

  void onNextStep() async {
    final dio = Dio();

    final email = emailController.text.trim();
    final code = codeController.text.trim();
    final new_password = passwordController.text;
    final confirm_password = confirmController.text;

    if (step == 1) {
      if(email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이메일을 입력해주세요')),
        );
        if (!_emailReg.hasMatch(email)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('올바른 이메일 형식이 아닙니다')),
          );
          return;
        }
      }
      if (isMock) {
        await Future.delayed(const Duration(milliseconds: 500));
        startTimer();
        setState(() => step = 2);
      } else {
        try {
          final response = await dio.post(
              'http://127.0.0.1:8000/send/',
              data: { 'email': email }
          );
          if (response.data['success'] == true) {
            startTimer();
            setState(() => step = 2);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('이메일 전송에 실패했습니다.')),
            );
          }
        } catch(e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('서버 오류: $e')),
          );
        }
      }
    } else if (step == 2) {
      if (code.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증번호를 입력해주세요')),
        );
        return;
      }
      if (isMock) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (code == '1234') {
          setState(() => step = 3);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('인증번호가 올바르지 않습니다.')),
          );
        }
      } else {
        try {
          final response = await dio.post(
            'http://127.0.0.1:8000/verify/',
            data: {
              'email': email,
              'code': code,
            },
          );
          if(response.data['verified'] == true) {
            setState(() => step = 3);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('인증번호가 올바르지 않습니다.')),
            );
          }
        } catch(e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('서버 오류: $e')),
          );
        }
      }
    } else if (step == 3) {
      if (new_password.isEmpty || confirm_password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('비밀번호를 모두 입력해주세요')),
        );
        return;
      }
      if (!_pwdReg.hasMatch(new_password)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('비밀번호는 최소 8자 이상, 숫자·영문·특수문자를 모두 포함해야 합니다.')),
        );
        return;
      }
      if (new_password != confirm_password) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
        );
        return;
      }
      if (isMock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("비밀번호가 성공적으로 변경되었습니다.")),
        );
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        try {
          final response = await dio.post(
            'http://127.0.0.1:8000/reset/',
            data: {
              'email': email,
              'new_password': new_password,
            },
          );
          if(response.statusCode == 200 && response.data['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("비밀번호가 성공적으로 변경되었습니다.")),
            );
            Future.delayed(const Duration(seconds: 1), () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("비밀번호 변경에 실패했습니다.")),
            );
          }
        } catch(e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('서버 오류: $e')),
          );
        }
      }
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
            Expanded(
              child: SingleChildScrollView(
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
                            hintStyle: TextStyle(color: Color(0xFF8E8E93)),
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
                            hintStyle: TextStyle(color: Color(0xFF8E8E93)),
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
                            hintStyle: TextStyle(color: Color(0xFF8E8E93)),
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
                            hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 17),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 10),
                    ButtonBox(
                      onPressed: onNextStep,
                      text: step == 1 ? '인증번호 요청' : step == 2 ? '인증번호 확인' : '비밀번호 재설정',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}