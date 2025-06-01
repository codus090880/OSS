import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:prunners/model/auth_service.dart';
import 'package:prunners/model/local_manager.dart';
import 'package:prunners/widget/button_box.dart';
import 'package:prunners/widget/grey_box.dart';
import 'package:prunners/widget/top_bar.dart';

enum Gender { male, female }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Gender? selectValue;
  File? _profileImage;

  // 레벨 옵션
  final List<String> levelOptions = ['Starter', 'Beginner', 'Intermediate', 'Advanced'];
  String? selectedLevel;

  // 텍스트 컨트롤러들
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController ageController      = TextEditingController();
  final TextEditingController heightController   = TextEditingController();
  final TextEditingController weightController   = TextEditingController();

  // 성별 레이블 맵
  final Map<Gender, String> labels = {
    Gender.male: "남성",
    Gender.female: "여성",
  };

  @override
  void initState() {
    super.initState();

    // 1) 서버 호출 인터셉터 설정 (기존)
    AuthService.setupInterceptor();

    // 2) SharedPreferences에 이미 저장된 프로필 이미지 경로가 있으면 불러오기
    _loadSavedProfileImage();
  }

  /// SharedPreferences에서 이미지 경로를 읽어서, _profileImage에 세팅
  Future<void> _loadSavedProfileImage() async {
    final savedPath = await LocalManager.getProfileImagePath();
    if (savedPath != null && savedPath.isNotEmpty) {
      final file = File(savedPath);
      if (await file.exists()) {
        setState(() {
          _profileImage = file;
        });
        return;
      }
      // 파일이 실제로 존재하지 않으면, 경로만 비워두기
      await LocalManager.setProfileImagePath('');
    }
  }

  /// 갤러리에서 이미지 선택 → 앱 전용 디렉터리에 profile.jpg로 복사 → 경로 저장
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked  = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      // 1. 앱 전용 문서 디렉터리 경로 가져오기
      final appDocDir = await getApplicationDocumentsDirectory();

      // 2. 복사할 파일 이름을 'profile.jpg'로 고정
      final newPath = path.join(appDocDir.path, 'profile.jpg');

      // 3. 기존에 같은 이름의 파일이 있으면 삭제(덮어쓰기 위해)
      final existingFile = File(newPath);
      if (await existingFile.exists()) {
        await existingFile.delete();
      }

      // 4. 갤러리에서 선택된 원본 파일을 profile.jpg로 복사
      final newFile = await File(picked.path).copy(newPath);

      // 5. 상태 업데이트 및 SharedPreferences에 경로 저장
      setState(() {
        _profileImage = newFile;
      });
      await LocalManager.setProfileImagePath(newFile.path);

    } catch (e) {
      debugPrint('이미지 복사/저장 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지를 저장하는 중 오류가 발생했습니다.')),
      );
    }
  }

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
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 65,
                    backgroundColor: Color(0xFFE0E0E0),
                    backgroundImage:
                    _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null
                        ? Icon(Icons.add_a_photo, size: 40, color: Colors.white70)
                        : null,
                  ),
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

              const SizedBox(height: 20),
              const Text('나이(만)'),
              const SizedBox(height: 10),
              GreyBox(
                child: TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
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
                  keyboardType: TextInputType.number,
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
                  keyboardType: TextInputType.number,
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

      //  저장 버튼 (완료)
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 50),
        child: ButtonBox(
          text: '완료',
          onPressed: () async {
            final nickname = nicknameController.text.trim();
            final gender   = selectValue == Gender.male ? 'male' : 'female';
            final age      = ageController.text.trim();
            final height   = heightController.text.trim();
            final weight   = weightController.text.trim();

            //   유효성 검사
            if (nickname.isEmpty ||
                age.isEmpty ||
                height.isEmpty ||
                weight.isEmpty ||
                selectValue == null ||
                selectedLevel == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('모든 항목을 입력해주세요')),
              );
              return;
            }

            final parsedAge    = int.tryParse(age);
            final parsedHeight = double.tryParse(height);
            final parsedWeight = double.tryParse(weight);

            if (parsedAge == null || parsedHeight == null || parsedWeight == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('숫자 형식이 올바르지 않습니다')),
              );
              return;
            }

            //   FormData 생성 및 서버 업로드
            try {
              final form = FormData();
              form.fields
                ..add(MapEntry('nickname', nickname))
                ..add(MapEntry('gender', gender))
                ..add(MapEntry('age', parsedAge.toString()))
                ..add(MapEntry('height', parsedHeight.toString()))
                ..add(MapEntry('weight', parsedWeight.toString()))
                ..add(MapEntry('level', selectedLevel!));

              if (_profileImage != null) {
                form.files.add(
                  MapEntry(
                    'profile_image',
                    await MultipartFile.fromFile(
                      _profileImage!.path,
                      filename: path.basename(_profileImage!.path),
                    ),
                  ),
                );
              }

              final saveResponse = await AuthService.dio.put(
                '/api/update-profile/',
                data: form,
              );

              // 서버에서 받은 프로필 URL(필요하다면)
              final profileUrl = saveResponse.data['profile_url'] as String?;
              // 로컬에 필요한 정보들 저장
              await LocalManager.setNickname(nickname);
              await LocalManager.setGender(gender);
              await LocalManager.setAge(parsedAge);
              await LocalManager.setHeight(parsedHeight);
              await LocalManager.setWeight(parsedWeight);
              await LocalManager.setLevel(selectedLevel!);

              // 서버에서 받은 URL도 SharedPreferences에 저장
              if (profileUrl != null) {
                await LocalManager.setProfileUrl(profileUrl);
              }


              if (saveResponse.statusCode == 200 || saveResponse.statusCode == 201) {

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('프로필 저장 완료')),
                );
                Navigator.pop(context);
              }
            } catch (e) {
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
