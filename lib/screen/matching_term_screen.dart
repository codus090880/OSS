import 'package:flutter/material.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/outlined_button_box.dart';
import 'package:dio/dio.dart';
import 'package:prunners/model/auth_service.dart';
import 'package:prunners/model/location_util.dart';

class MatchingTermScreen extends StatefulWidget {
  const MatchingTermScreen({super.key});

  @override
  State<MatchingTermScreen> createState() => _MatchingTermScreen();
}

class _MatchingTermScreen extends State<MatchingTermScreen> {
  String? _selectedDistance;
  String? _selectedGender;

  final List<Map<String, String>> distanceOptions = [
    {'label': '3~5km', 'value': '3-5'},
    {'label': '5~7km', 'value': '5-7'},
    {'label': '7~10km', 'value': '7-10'},
    {'label': '10km 이상', 'value': '10+'},
  ];
  final List<String> genderOptions = ['성별 무관', '남성 선호', '여성 선호'];

  Future<void> _startMatching() async {
    if (_selectedDistance == null || _selectedGender == null) return;

    // 매칭 화면 push
    Navigator.pushNamed(context, '/matching');

    try {
      // 위치 업데이트 -> 현재 위치 가져오기
      final position = await LocationUtil.getCurrentPosition();
      if (position != null) {
        await AuthService.dio.post(
          '/location/update/',
          data: {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
        );
      } else {
        print('[WARNING] 위치 정보 가져오기 실패 → 위치 업데이트 스킵');
      }

      await AuthService.dio.post(
        '/match/preference/',
        data: {
          'preferred_gender': _selectedGender == '성별 무관'
              ? 'any'
              : (_selectedGender == '남성 선호' ? 'male' : 'female'),
          'preferred_distance_range': _selectedDistance,
          'allow_push': true,
        },
      );

      // 매칭 요청
      final response = await AuthService.dio.post(
        '/match/start/',
        data: {
          'preferred_distance': _selectedDistance,
          'preferred_gender': _selectedGender,
        },
      );

      if (response.statusCode == 200) {
        final result = response.data;
        print('매칭 결과: $result');

        if (result['matched'] == true) {
          // 채팅방으로 이동
          Navigator.pushReplacementNamed(
            context,
            '/chatroom',
            arguments: {
              'room_id': result['room_id'],
              'room_name': result['room_name'],
              'is_public': result['is_public'],
            },
          );
        } else {
          // 실패 → 실패 화면으로 이동
          Navigator.pushReplacementNamed(context, '/matching_failed');
        }
      } else {
        Navigator.pop(context); // MatchingScreen pop
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('매칭 요청 실패: ${response.statusCode}')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // MatchingScreen pop
      print('매칭 요청 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('매칭 요청 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFormValid = _selectedDistance != null && _selectedGender != null;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(title: '1:1 매칭'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 10, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '함께 달릴 러닝 메이트 조건을 설정해주세요',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 35),

              // 거리 선택
              const Text('희망 러닝 거리', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: distanceOptions.map((item) {
                    final isSelected = _selectedDistance == item['value'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: OutlinedButton(
                        onPressed: () => setState(() => _selectedDistance = item['value']),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected ? Colors.black87 : Colors.black12,
                            width: isSelected ? 2.5 : 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text(
                          item['label']!,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 35),

              // 성별 선택
              const Text('선호 성별', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: genderOptions.map((label) {
                  final isSelected = _selectedGender == label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: OutlinedButton(
                      onPressed: () => setState(() => _selectedGender = label),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: isSelected ? Colors.black87 : Colors.black12,
                          width: isSelected ? 2.5 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const Spacer(),

              // 매칭 시작하기 버튼
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Opacity(
                  opacity: isFormValid ? 1 : 0.5,
                  child: IgnorePointer(
                    ignoring: !isFormValid,
                    child: OutlinedButtonBox(
                      text: '매칭 시작하기',
                      onPressed: _startMatching,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}