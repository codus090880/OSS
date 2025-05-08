import 'package:flutter/material.dart';
import 'package:prunners/widget/outlined_button_box.dart';
import 'package:prunners/widget/bottom_bar.dart';

class EvaluateScreen extends StatefulWidget {
  const EvaluateScreen({super.key});

  @override
  State<EvaluateScreen> createState() => _EvaluateScreenState();
}

class _EvaluateScreenState extends State<EvaluateScreen> {
  String mateName = '홍길동';
  bool isPositive = true;
  List<String> selectedReasons = [];

  List<String> positiveReasons = [
    '시간 약속을 잘 지켰어요',
    '대화가 편하고 즐거웠어요',
    '매너가 좋아요',
    '러닝 스타일이 잘 맞았어요',
    '다음에도 함께 달리고 싶어요',
  ];

  List<String> negativeReasons = [
    '시간 약속을 지키지 않았어요',
    '약속 장소에 나타나지 않았어요',
    '연락이 잘 되지 않았어요',
    '러닝 스타일이 많이 달랐어요',
    '불편하거나 무례하게 느껴졌어요',
  ];

  @override
  Widget build(BuildContext context) {
    List<String> currentList = isPositive ? positiveReasons : negativeReasons;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '러닝 메이트',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 25,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
              onPressed: () {
                // 신고 로직
              },
              icon: Icon(
                Icons.notifications_none,
                color: Colors.black,
                size: 32,
              )
          )
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) return;
            Navigator.pushReplacementNamed(context, ['/home', '/running', '/profile'][index]);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              const Text(
                '함께 달린 러닝메이트 평가해주세요',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Icon(
                Icons.account_circle,
                size: 130,
                color: Color(0xFFE0E0E0),
              ),
              const SizedBox(height: 10),
              Text(
                mateName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButtonBox(
                      text: '좋았어요 😊',
                      onPressed: () {
                        setState(() {
                          isPositive = true;
                        });
                      },
                      borderColor: Colors.black,
                      borderWidth: isPositive ? 2.0 : 1.0,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButtonBox(
                      text: '아쉬웠어요 🙁',
                      onPressed: () {
                        setState(() {
                          isPositive = false;
                        });
                      },
                      borderColor: Colors.black,
                      borderWidth: !isPositive ? 2.0 : 1.0,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...currentList.map((reason) {
                final isSelected = selectedReasons.contains(reason);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        if (isSelected) {
                          selectedReasons.remove(reason);
                        } else {
                          selectedReasons.add(reason);
                        }
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.black,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      minimumSize: Size.fromHeight(55),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: Colors.black,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Center(
                            child: Text(
                              reason,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 10),
              OutlinedButtonBox(
                text: '제출하기',
                onPressed: () {
                  // 제출 내용 검증, 저장 로직
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}