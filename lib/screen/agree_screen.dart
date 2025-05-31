import 'package:flutter/material.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/outlined_button_box.dart';
import 'package:prunners/screen/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prunners/model/push.dart';


class AgreeScreen extends StatefulWidget {
  const AgreeScreen({super.key});

  @override
  State<AgreeScreen> createState() => _AgreeScreenState();
}

class _AgreeScreenState extends State<AgreeScreen> {
  // 전문보기 눌렀을 때 띄우는 함수
  void showAgreementDetail(int index) {
    String title = '';
    String content = '';

    // 약관 내용 설정
    switch (index) {
      case 1:
        title = '서비스 이용 약관(필수)';
        content = '''
[제1조 목적]
본 약관은 [PRUNNERS] (이하 "서비스")의 이용 조건 및 절차, 회원과 서비스 제공자의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.

[제2조 용어의 정의]
① "회원"이란 서비스에 개인정보를 제공하여 회원가입을 완료한 자를 말합니다.
② "서비스"란 회사가 제공하는 러닝 코스 추천, 러닝 매칭, 위치 기반 서비스, 커뮤니티 등 일체의 서비스를 의미합니다.

[제4조 서비스 내용]
① 서비스는 러닝 코스 추천, 사용자 간 매칭, 푸시 알림, 커뮤니티 제공 기능을 포함합니다.
② 서비스 내용은 운영상의 필요에 따라 변경될 수 있으며, 변경 시 공지합니다.

[제5조 회원의 의무]
① 회원은 서비스 이용 시 관련 법령 및 본 약관을 준수해야 합니다.
② 회원은 타인의 권리를 침해하거나 불쾌감을 주는 행위를 해서는 안 됩니다.

[제6조 안전 주의사항 및 면책]
① 회원은 개인 건강 상태 및 주의를 확인한 후 서비스를 이용해야 합니다.
② 서비스 이용 중 발생한 부상, 사고, 법규 위반 등에 대해 회사는 법적 책임을 지지 않습니다.
③ 회원은 교통 법규 및 안전 수칙을 준수하여야 합니다.

[제9조 책임의 제한]
① 서비스 제공자는 회원 간 발생하는 러닝 매칭 후 개인적 분쟁에 책임을 지지 않습니다.
② 서비스 제공자는 천재지변, 불가항력적 사유로 인한 서비스 장애에 대해 책임을 지지 않습니다.

[제10조 약관의 개정]
① 본 약관은 서비스 화면에 게시하거나 기타 방법으로 회원에게 고지함으로써 효력이 발생합니다.
② 서비스 제공자는 약관을 변경할 수 있으며 변경 시 사전 고지합니다.

[제11조 기타]
본 약관에 명시되지 않은 사항은 관계 법령 및 상관례에 따릅니다.

''';
        break;

        case 2:
        title = '개인정보 처리방침(필수)';
        content = '''
[제3조 개인정보 보호 및 위치정보 이용 동의]
① 서비스 이용 시 위치정보가 수집 및 활용됩니다.
② 사용자는 위치정보 수집 및 이용에 동의해야 서비스를 원활히 이용할 수 있습니다.
③ 자세한 개인정보 보호 사항은 개인정보 처리방침을 따릅니다.

[제8조 회원 탈퇴 및 데이터 처리]
① 회원은 언제든지 서비스 내 회원탈퇴 메뉴를 통해 탈퇴할 수 있습니다.
② 탈퇴 후 법령에 의해 보존이 필요한 정보를 제외한 모든 개인정보는 삭제됩니다.
''';
        break;

        case 3:
        title = '푸쉬 알림 동의(선택)';
        content = '''
[제7조 푸시 알림]
① 서비스는 러닝 일정 안내, 코스 추천, 커뮤니티 알림 등을 푸시 알림으로 제공합니다.
② 회원은 앱 내 설정에서 푸시 알림 수신 여부를 변경할 수 있습니다.
③ 푸시 알림 미수신으로 인한 불이익에 대해 회사는 책임을 지지 않습니다.
''';
        break;
    }

    // 모달 띄우기
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                height: 300, // 원하는 높이
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('닫기'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _allChecked = false;
  bool _isChecked1 = false;
  bool _isChecked2 = false;
  bool _isChecked3 = false;
  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();
  }

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
        _isButtonPressed = _isChecked1 && _isChecked2;
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
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: CustomTopBar(title: '약관 동의'),
        ),
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
              AgreementItem(1, '서비스 이용 약관(필수)'),
              AgreementItem(2, '개인정보 처리방침(필수)'),
              AgreementItem(3, '푸시 알림 동의(선택)'),
            ],
          ),
        ),
      ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 60),
          child: _isButtonPressed ? OutlinedButtonBox(
            text: '확인',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('pushEnabled', _isChecked3);
              await PushNotificationService.initialize();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
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
                showAgreementDetail(index);
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


