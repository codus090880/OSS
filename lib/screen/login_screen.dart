import 'package:flutter/material.dart';
import 'package:prunners/screen/home_screen.dart';
import 'package:prunners/screen/signup_screen.dart';
import 'package:prunners/widget/grey_box.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/button_box.dart';
import 'package:prunners/widget/outlined_button_box.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                    hintText: '아이디를 입력하세요',
                    hintStyle: TextStyle(
                      color: Color(0xFF8E8E93), // 회색빛
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 17),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GreyBox(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '비밀번호를 입력하세요',
                    hintStyle: TextStyle(
                      color: Color(0xFF8E8E93), // 회색빛
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 17),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    '아이디/비밀번호 찾기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6A707C),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ButtonBox(
                text: '로그인',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButtonBox(
                text: '회원가입',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignupScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
