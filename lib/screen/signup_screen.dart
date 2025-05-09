// lib/screen/signup_screen.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:prunners/screen/login_screen.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/grey_box.dart';
import 'package:prunners/widget/button_box.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    // 간단한 비밀번호 확인
    if (password != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('https://your.api/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ok')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('가입 실패: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TopBar(),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 100.0),
                      child: const Text(
                        '계획 없이 달리는 날',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),

                    GreyBox(
                      child: TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: '이메일',
                          hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 17),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GreyBox(
                      child: TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: '비밀번호',
                          hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 17),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GreyBox(
                      child: TextField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: '비밀번호 확인',
                          hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 17),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ButtonBox(
                      text: '회원가입',
                      onPressed: _signUp,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: RichText(
                text: TextSpan(
                  text: '이미 아이디가 있다면? ',
                  style: const TextStyle(
                    color: Color(0xFF6A707C),
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: '로그인',
                      style: const TextStyle(
                        color: Color(0xFF007AFF),
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
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
