import 'package:flutter/material.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/outlined_button_box.dart';

class RunningmateTermScreen extends StatefulWidget {
  const RunningmateTermScreen({super.key});

  @override
  State<RunningmateTermScreen> createState() => _RunningmateTermScreenState();
}

class _RunningmateTermScreenState extends State<RunningmateTermScreen> {
  String? _selectedDistance;
  String? _selectedGender;

  final List<String> distanceOptions = ['3~5km', '5~7km', '7~10km', '10km 이상'];
  final List<String> genderOptions = ['성별 무관', '남성 선호', '여성 선호'];

  @override
  Widget build(BuildContext context) {
    final isFormValid = _selectedDistance != null && _selectedGender != null;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(title: '러닝 메이트 정보'),
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
                  children: distanceOptions.map((label) {
                    final isSelected = _selectedDistance == label;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: OutlinedButton(
                        onPressed: () => setState(() => _selectedDistance = label),
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
                      onPressed: () {
                        Navigator.pushNamed(context, '/matching');
                      },
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