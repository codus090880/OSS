import 'package:flutter/material.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/grey_box.dart';
import 'package:prunners/widget/button_box.dart';
import 'package:prunners/model/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final _pwdReg = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$');

  Future<void> changePassword() async {
    final currentPassword = currentPasswordController.text;
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 입력해주세요.')),
      );
      return;
    }

    if (!_pwdReg.hasMatch(newPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호는 최소 8자 이상, 숫자·영문·특수문자를 모두 포함해야 합니다.')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('새 비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    try {
      final response = await AuthService.dio.post(
        '/api/change-password/',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다.')),
        );
        Navigator.pop(context); // 변경 후 뒤로 돌아가기
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호 변경에 실패했습니다. 현재 비밀번호를 확인해주세요.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버 오류: $e')),
      );
    }
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(title: '비밀번호 변경'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GreyBox(
                child: TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: '현재 비밀번호 입력해주세요',
                    hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 17),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GreyBox(
                child: TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: '새로운 비밀번호 입력해주세요',
                    hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 17),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GreyBox(
                child: TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: '비밀번호 재확인',
                    hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 17),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ButtonBox(
                text: '비밀번호 변경',
                onPressed: changePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
