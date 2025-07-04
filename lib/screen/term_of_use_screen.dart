import 'package:flutter/material.dart';
import 'package:prunners/widget/top_bar.dart';

class TermOfUseScreen extends StatelessWidget {
  const TermOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomTopBar(title: '이용 약관'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Text(
                  '''
[제1조 목적]
본 약관은 [PRUNNERS] (이하 "서비스")의 이용 조건 및 절차, 회원과 서비스 제공자의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.

[제2조 용어의 정의]
① "회원"이란 서비스에 개인정보를 제공하여 회원가입을 완료한 자를 말합니다.
② "서비스"란 회사가 제공하는 러닝 코스 추천, 러닝 매칭, 위치 기반 서비스, 커뮤니티 등 일체의 서비스를 의미합니다.

[제3조 개인정보 보호 및 위치정보 이용 동의]
① 서비스 이용 시 위치정보가 수집 및 활용됩니다.
② 사용자는 위치정보 수집 및 이용에 동의해야 서비스를 원활히 이용할 수 있습니다.
③ 자세한 개인정보 보호 사항은 개인정보 처리방침을 따릅니다.

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

[제7조 푸시 알림]
① 서비스는 러닝 일정 안내, 코스 추천, 커뮤니티 알림 등을 푸시 알림으로 제공합니다.
② 회원은 앱 내 설정에서 푸시 알림 수신 여부를 변경할 수 있습니다.
③ 푸시 알림 미수신으로 인한 불이익에 대해 회사는 책임을 지지 않습니다.

[제8조 회원 탈퇴 및 데이터 처리]
① 회원은 언제든지 서비스 내 회원탈퇴 메뉴를 통해 탈퇴할 수 있습니다.
② 탈퇴 후 법령에 의해 보존이 필요한 정보를 제외한 모든 개인정보는 삭제됩니다.

[제9조 책임의 제한]
① 서비스 제공자는 회원 간 발생하는 러닝 매칭 후 개인적 분쟁에 책임을 지지 않습니다.
② 서비스 제공자는 천재지변, 불가항력적 사유로 인한 서비스 장애에 대해 책임을 지지 않습니다.

[제10조 약관의 개정]
① 본 약관은 서비스 화면에 게시하거나 기타 방법으로 회원에게 고지함으로써 효력이 발생합니다.
② 서비스 제공자는 약관을 변경할 수 있으며 변경 시 사전 고지합니다.

[제11조 기타]
본 약관에 명시되지 않은 사항은 관계 법령 및 상관례에 따릅니다.
                  ''',
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
