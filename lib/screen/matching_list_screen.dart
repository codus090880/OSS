import 'package:flutter/material.dart';
import 'package:prunners/widget/top_bar.dart';
import 'chat_detail_screen.dart';
import 'package:prunners/widget/bottom_bar.dart';

class MatchingListScreen extends StatefulWidget {
  const MatchingListScreen({super.key});

  @override
  State<MatchingListScreen> createState() => _MatchingListScreenState();
}

class _MatchingListScreenState extends State<MatchingListScreen> {
  final List<Map<String, dynamic>> chatRooms = [
    {
      'roomName': '아침 러닝',
      'preference': '남성 선호',
      'distance': '5~7km',
      'users': [
        {
          'name': '홍길동',
          'gender': '남성',
          'mannerTemp': 38.0,
          'level': 'Beginner',
        },
        {
          'name': '김땡땡',
          'gender': '남성',
          'mannerTemp': 37.0,
          'level': 'Advanced',
        },
      ],
    },
    {
      'roomName': '야간 번개 러닝',
      'preference': '성별 무관',
      'distance': '3~5km',
      'users': [
        {
          'name': '김아무개',
          'gender': '여성',
          'mannerTemp': 39.5,
          'level': 'Intermediate',
        },
        {
          'name': '도민준',
          'gender': '남성',
          'mannerTemp': 39.0,
          'level': 'Intermediate',
        },
      ],
    },
    {
      'roomName': '김철수, 김영희의 채팅방',
      'preference': '성별 무관',
      'distance': '7~10km',
      'users': [
        {
          'name': '김철수',
          'gender': '남성',
          'mannerTemp': 39.5,
          'level': 'Intermediate',
        },
        {
          'name': '김영희',
          'gender': '여성',
          'mannerTemp': 38.5,
          'level': 'Intermediate',
        },
      ],
    },
  ];

  void enterDetail(int index) {
    final selectedChatRoomUsers = chatRooms[index]['users'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(users: selectedChatRoomUsers),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(title: '러닝 메이트 채팅방'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1:1 매칭을 원하시면 아래 버튼을 눌러주세요.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12), // 설명과 버튼 사이 여백
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF333333), width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/matching_term');
                      },
                      child: const Text(
                        '1:1 매칭 시작하기',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF222222),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 0, bottom: 8),
                itemCount: chatRooms.length,
                itemBuilder: (context, index) {
                  final room = chatRooms[index];
                  return GestureDetector(
                    onTap: () => enterDetail(index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.group, size: 40),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room['roomName'] ?? '(제목 없음)',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '# ${room['preference'] ?? '정보 없음'}   # ${room['distance'] ?? '거리 정보 없음'}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(
          currentIndex: 1,
          onTap: (index) {
            if (index == 1) return;
            Navigator.pushReplacementNamed(
              context,
              ['/home', '/running', '/course', '/profile'][index],
            );
          },
        ),
      ),
    );
  }
}