import 'package:flutter/material.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/outlined_button_box.dart';

class AgreeScreen extends StatefulWidget {
  const AgreeScreen({super.key});

  @override
  State<AgreeScreen> createState() => _AgreeScreenState();
}

class _AgreeScreenState extends State<AgreeScreen> {
  bool _allChecked = false;
  bool _isChecked1 = false;
  bool _isChecked2 = false;
  bool _isChecked3 = false;
  bool _isButtonPressed = false;

  // 전체 동의 처리
    void updateAllchecked() {
    setState(() {
      _allChecked = !_allChecked;
      if(_allChecked) {
        _isChecked1 = true;
        _isChecked2 = true;
        _isChecked3 = true;
        _isButtonPressed = true;
      } else {
        _isChecked1 = false;
        _isChecked2 = false;
        _isChecked3 = false;
        _isButtonPressed = false;
      }
    });
  }

  void active_button() {
      setState(() {
        _isButtonPressed = _isChecked2 && _isChecked3;
        _allChecked = _isChecked1 && _isChecked2 && _isChecked3;
      });
  }

  // 체크 여부
  void toggleCheck(int index) {
    setState(() {
      if(index == 1) _isChecked1 = !_isChecked1;
      if(index == 2) _isChecked2 = !_isChecked2;
      if(index == 3) _isChecked3 = !_isChecked3;

      active_button();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomTopBar(title: '약관 동의'),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopBar(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 100.0),
                child: const Text(
                  '계획 없이 달리는 날',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ),
              const SizedBox(height: 100),
              GestureDetector(
                onTap: updateAllchecked,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Icon(Icons.check, color: Colors.white, size: 20),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                              '모두 동의',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 42),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              AgreementItem(1, '서비스 이용 약관(선택)'),
              AgreementItem(2, '서비스 이용 약관(필수)'),
              AgreementItem(3, '서비스 이용 약관(필수)'),
            ],
          ),
        ),
      ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 60),
          child: _isButtonPressed ? OutlinedButtonBox(
            text: '확인',
            onPressed: () {},
          ) : AbsorbPointer(
            child: Opacity(
              opacity: 0.3,
              child: OutlinedButtonBox(
                text: '확인',
                onPressed: () {},
              ),
            )
          )
        )
    );
  }
  Widget AgreementItem(int index, String label) {
    bool isChecked;
    switch (index) {
      case 1:
        isChecked = _isChecked1;
        break;
      case 2:
        isChecked = _isChecked2;
        break;
      case 3:
        isChecked = _isChecked3;
        break;
      default:
        isChecked = false;
    }
    return GestureDetector(
      onTap: () => toggleCheck(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isChecked ? Colors.black : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // 전문보기 페이지 열기
              },
              child: const Text(
                '전문보기',
                style: TextStyle(
                  color: Color(0xFF424242), // 글자색
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF424242), // 밑줄색
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

