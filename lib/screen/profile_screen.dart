import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:prunners/widget/button_box.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/grey_box.dart';
import 'package:prunners/model/local_manager.dart';

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
  final List<String> levelOptions = ['Starter', 'Beginner', 'Intermediate', 'Advanced'];
  String? selectedLevel;


  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(title: '프로필 설정'),
      ),
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
              const SizedBox(height: 10),
              const Text('레벨'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedLevel,
                onChanged: (value) {
                  setState(() {
                    selectedLevel = value;
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFF7F8F9),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                  hintText: '레벨을 선택하세요',
                ),
                items: levelOptions.map((level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 50),
        child: ButtonBox(
          text: '완료',
          onPressed: () async {
            // 프로필 정보 저장 로직
            final nickname = nicknameController.text.trim();
            final gender = selectValue == Gender.male ? 'male' : 'female';
            final age = ageController.text.trim();
            final height = heightController.text.trim();
            final weight = weightController.text.trim();

            // 유효성 검사
            if(nickname.isEmpty || age.isEmpty || height.isEmpty || weight.isEmpty
                || selectValue == null || selectedLevel == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('모든 항목을 입력해주세요')),
              );
              return;
            }

            final parsedAge = int.tryParse(age);
            final parsedHeight = double.tryParse(height);
            final parsedWeight = double.tryParse(weight);

            if(parsedAge == null || parsedHeight ==  null || parsedWeight == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('숫자 형식이 올바르지 않습니다')),
              );
              return;
            }

            final dio = Dio();
            try {
              // 닉네임 중복 검사
              final checkResponse = await dio.post(
                'http://127.0.0.1:8000/check_nickname/',
                data: {'nickname': nickname},
                options: Options(headers: {'Content-Type': 'application/json'}),
              );
              if (checkResponse.data['exists'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('이미 사용 중인 닉네임입니다')),
                );
                return;
              }
              // 프로필 저장
              final saveResponse = await dio.post(
                'http://127.0.0.1:8000/user_set/',
                data: {
                  'nickname': nickname,
                  'gender' : gender,
                  'age' : parsedAge,
                  'height': parsedHeight,
                  'weight': parsedWeight,
                  'level': selectedLevel,
                },
                options: Options(
                  headers: {'content-Type': 'application/json'},
                ),
              );
              if (saveResponse.statusCode == 201 || saveResponse.statusCode == 200) {
                await LocalManager.setNickname(nickname);
                await LocalManager.setGender(gender);
                await LocalManager.setAge(parsedAge);
                await LocalManager.setHeight(parsedHeight);
                await LocalManager.setWeight(parsedWeight);
                await LocalManager.setLevel(selectedLevel!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('프로필 저장 완료')),
                );
                Navigator.pop(context);
              }
            } catch(e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('저장 실패: $e')),
              );
            }
          },
        ),
      ),
    );
  }
}
