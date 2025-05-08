import 'package:flutter/material.dart';
import 'package:prunners/widget/button_box.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/grey_box.dart';

enum Gender { male, female }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Gender ?selectValue;
  final Map<Gender, String> labels = {
    Gender.male: "남성",
    Gender.female: "여성",
  };

  final nicknameController = TextEditingController();
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomTopBar(title: '프로필 설정'),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Icon(
                    Icons.account_circle,
                    size: 130,
                    color: Color(0xFFE0E0E0),
                  ),
              ),
              const SizedBox(height: 30),
              const Text('닉네임'),
              const SizedBox(height: 10),
              GreyBox(
                child: TextField(
                  controller: nicknameController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 17),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text('성별'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: Gender.values.map((value) {
                    return Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            labels[value]!,
                            style: const TextStyle(fontSize: 15),
                          ),
                          Radio<Gender>(
                            value: value,
                            groupValue: selectValue,
                            onChanged: (Gender? newValue) {
                              setState(() {
                                selectValue = newValue!;
                              });
                            },
                            activeColor: Colors.deepPurple,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              const Text('나이(만)'),
              const SizedBox(height: 10),
              GreyBox(
                child: TextField(
                  controller: ageController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 17),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text('키(cm)'),
              const SizedBox(height: 10),
              GreyBox(
                child: TextField(
                  controller: heightController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 17),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text('몸무게(kg)'),
              const SizedBox(height: 10),
              GreyBox(
                child: TextField(
                  controller: weightController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 17),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 50),
        child: ButtonBox(
          text: '완료',
          onPressed: () {
            // 프로필 정보 저장 로직
          },
        ),
      ),
    );
  }
}
