import 'package:flutter/material.dart';
import 'package:prunners/widget/rounded_shadow_box.dart';
import 'package:prunners/widget/button_box.dart';

class AfterMatching extends StatelessWidget {
  Widget _buildActivityItem(
      String dateLabel, String distance, String paceOrTime) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // 활동 이미지
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: AssetImage('111.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 12),
          // 텍스트 3개
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 4),
              Text(
                distance,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 4),
              Text(
                paceOrTime,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 앱바, 바텀 네비게이션 없이
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 사용자 프로필
              Row(
                children: [
                  Icon(Icons.account_circle, size: 60, color: Colors.grey),
                  SizedBox(width: 12),
                  Text(
                    '사용자',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // 매너 온도 & 레벨 박스
              Row(
                children: [
                  Expanded(
                    child: RoundedShadowBox(
                      width: double.infinity,
                      height: 80,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '매너 온도',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.device_thermostat,
                                  size: 34, color: Colors.black),
                              SizedBox(width: 16),
                              Text(
                                '38.0',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: RoundedShadowBox(
                      width: double.infinity,
                      height: 80,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '레벨',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.leaderboard,
                                  size: 34, color: Colors.black),
                              SizedBox(width: 16),
                              Text(
                                'Beginner',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // 해시태그
              Row(
                children: [
                  Text(
                    '#매너가 좋은',
                    style: TextStyle(
                      color: Color(0xFF34C2C1),
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    '#시간을 잘 지키는',
                    style: TextStyle(
                      color: Color(0xFF34C2C1),
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              // 최근 활동 섹션
              Text(
                '최근 활동',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 12),
              // 활동 아이템 박스
              RoundedShadowBox(
                width: double.infinity,
                child: Column(
                  children: [
                    _buildActivityItem('어제', '3.33 km', '6’22’’ 페이스'),
                    Divider(
                        height: 1, thickness: 1, color: Colors.black.withOpacity(0.1)),
                    _buildActivityItem('2025. 4. 4', '6.54 km', '5’16’’ 페이스'),
                    Divider(
                        height: 1, thickness: 1, color: Colors.black.withOpacity(0.1)),
                    _buildActivityItem('2025. 4. 2', '10.07 km', '5’53’’ 페이스'),
                  ],
                ),
              ),
              SizedBox(height: 24),
              // 스크롤되는 버튼 영역
              ButtonBox(
                text: '수락하기',
                onPressed: () {
                  // TODO: 수락 로직
                },
              ),
              SizedBox(height: 12),
              ButtonBox(
                text: '거절하기',
                onPressed: () {
                  // TODO: 거절 로직
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}