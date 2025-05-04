import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:prunners/screen/home_screen.dart';
import 'package:prunners/screen/login_screen.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/grey_box.dart';
import 'package:prunners/widget/button_box.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TopBar(),
                    const SizedBox(height: 8),
                    const Text(
                      '계획 없이 달리는 날',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    const SizedBox(height: 80),
                    GreyBox(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '아이디',
                          hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 17),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GreyBox(
                      child: TextField(
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 20),
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
