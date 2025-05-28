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
        child: ListView.builder(
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
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
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
                            '# ${room['preference'] ?? '정보 없음'}',
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