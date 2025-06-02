import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:prunners/screen/home_screen.dart';
import 'package:prunners/screen/reset_password_screen.dart';
import 'package:prunners/screen/signup_screen.dart';
import 'package:prunners/widget/grey_box.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/button_box.dart';
import 'package:prunners/widget/outlined_button_box.dart';

final storage = FlutterSecureStorage();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final Dio dio = Dio();

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = idController.text.trim();
    final password = passwordController.text.trim();

    if (email == '1234' && password == '1234') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('디버깅용 로그인 성공!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
      return;
    }

    try {
      final response = await dio.post(
        'https://a10e-121-160-204-245.ngrok-free.app/api/token/',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      print('[DEBUG] 응답 수신: ${response.statusCode}');
      print('[DEBUG] 응답 데이터: ${response.data}');
      if (response.statusCode == 200) {
        final accessToken = response.data['access'];
        final refreshToken = response.data['refresh'];

        await storage.write(key: 'ACCESS_TOKEN', value: accessToken);
        await storage.write(key: 'REFRESH_TOKEN', value: refreshToken);


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 성공!')),
        );


        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } on DioException catch (e) {
      print('[DEBUG] Dio 오류 타입: ${e.type}');
      print('[DEBUG] Dio 오류 메시지: ${e.message}');
      print('[DEBUG] Dio 요청 URL: ${e.requestOptions.uri}');
      print('[DEBUG] Dio 응답 데이터: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이메일 또는 비밀번호가 올바르지 않습니다')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('네트워크 연결 오류 발생: ${e.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('예기치 않은 오류 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                child: Text(
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
                  controller: idController,
                  decoration: InputDecoration(
                    hintText: '이메일을 입력하세요',
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
                    hintText: '비밀번호를 입력하세요',
                    hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 17),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ResetPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    '비밀번호를 잊으셨나요?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6A707C),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ButtonBox(text: '로그인', onPressed: _login),
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
