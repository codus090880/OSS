import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/model/auth_service.dart';
import 'chat_detail_screen.dart';

class MatchingListScreen extends StatefulWidget {
  const MatchingListScreen({super.key});

  @override
  State<MatchingListScreen> createState() => _MatchingListScreenState();
}

class _MatchingListScreenState extends State<MatchingListScreen> {
  /// API로부터 받아올 공개 채팅방 목록 (room_id, title, distance_km 세 개만)
  List<Map<String, dynamic>> _publicRooms = [];

  /// 내가 이미 참여한 채팅방 ID (없으면 null)
  int? _joinedRoomId;

  bool _loadingRooms = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 공개 채팅방 목록과 내가 참여한 방 ID를 동시에 가져옵니다.
    //_fetchPublicRooms();
    //_fetchMyRoom();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() { _loadingRooms = true; _errorMessage = null; });
    try {
      final results = await Future.wait([
        AuthService.dio.get<List<dynamic>>('/chatrooms/public/nearby/'),
        AuthService.dio.get<Map<String, dynamic>>('/chatrooms/my/')
      ]);

      // 1) 공개 방 목록 처리
      final publicResponse = results[0] as Response<List<dynamic>>;
      final List<Map<String, dynamic>> rooms = [];
      if (publicResponse.statusCode == 200 && publicResponse.data != null) {
        rooms.addAll(publicResponse.data!
            .whereType<Map<String, dynamic>>()
            .map((item) => {
          'room_id': item['room_id'],
          'title': item['title'],
          'distance_km': item['distance_km'],
        })
        );
      }
      // 2) 내가 속한 방 ID 처리
      final myResponse = results[1] as Response<Map<String, dynamic>>;
      final joinedId = myResponse.data?['room_id'] as int?;

      setState(() {
        _publicRooms = rooms;
        _joinedRoomId = joinedId;
        _loadingRooms = false;
      });
    } on DioError catch (err) {
      // 에러 핸들링 (둘 중 하나라도 에러면 _loadingRooms=false 하고 _errorMessage 세팅)
      String message;
      if (err.response?.statusCode == 400) {
        message = '위치 정보가 없습니다. 위치 권한을 확인해주세요.';
      } else if (err.response?.statusCode == 403) {
        message = '공개 채팅방 목록을 볼 권한이 없습니다.';
      } else {
        message = '방 목록을 불러오는 중 오류가 발생했습니다.';
      }
      setState(() {
        _loadingRooms = false;
        _errorMessage = message;
        _joinedRoomId = null;
        _publicRooms = [];
      });
    } catch (e) {
      setState(() {
        _loadingRooms = false;
        _errorMessage = '알 수 없는 오류가 발생했습니다.';
        _joinedRoomId = null;
        _publicRooms = [];
      });
    }
  }

  /// 1) 주변 공개 채팅방 목록 조회
  /*Future<void> _fetchPublicRooms() async {
    setState(() {
      _loadingRooms = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.dio.get<List<dynamic>>(
        '/chatrooms/public/nearby/',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null) {
          final rooms = data
              .whereType<Map<String, dynamic>>()
              .map((item) => {
            'room_id': item['room_id'],
            'title': item['title'],
            'distance_km': item['distance_km'],
          })
              .toList();

          setState(() {
            _publicRooms = rooms;
            _loadingRooms = false;
          });
        } else {
          setState(() {
            _publicRooms = [];
            _loadingRooms = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
          '상태 코드 ${response.statusCode}로 방 목록을 가져오지 못했습니다.';
          _loadingRooms = false;
        });
      }
    } on DioError catch (err) {
      if (err.response?.statusCode == 400) {
        _errorMessage = '위치 정보가 없습니다. 위치 권한을 확인해주세요.';
      } else if (err.response?.statusCode == 403) {
        _errorMessage = '공개 채팅방 목록을 볼 권한이 없습니다.';
      } else {
        _errorMessage = '방 목록을 불러오는 중 오류가 발생했습니다.';
      }
      setState(() {
        _loadingRooms = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '알 수 없는 오류가 발생했습니다.';
        _loadingRooms = false;
      });
    }
  }

  /// 2) 내가 이미 참여한 채팅방 ID 조회
  Future<void> _fetchMyRoom() async {
    try {
      final response = await AuthService.dio.get<Map<String, dynamic>>(
        '/chatrooms/my/',
      );
      final roomId = response.data?['room_id'] as int?;
      setState(() {
        _joinedRoomId = roomId;
      });
    } catch (e) {
      // 에러가 나도 별도 처리 없이 참여한 방이 없는 것으로 간주
      setState(() {
        _joinedRoomId = null;
      });
    }
  }*/

  void _enterDetail(int index) {
    final room = _publicRooms[index];
    final roomId = room['room_id'] as int;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          roomId: roomId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(title: '주변 공개 채팅방'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1:1 매칭 버튼
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side:
                        const BorderSide(color: Color(0xFF333333), width: 1),
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

            // API 호출 결과에 따라 로딩 / 에러 / 방 목록 표시
            if (_loadingRooms)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else if (_publicRooms.isEmpty)
                const Expanded(
                  child: Center(child: Text('주변에 공개 채팅방이 없습니다.')),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 0, bottom: 8),
                    itemCount: _publicRooms.length,
                    itemBuilder: (context, index) {
                      final room = _publicRooms[index];
                      final title = room['title'] as String? ?? '(제목 없음)';
                      final distance = room['distance_km'] as num? ?? 0;
                      final roomId = room['room_id'] as int;

                      // 이미 참여한 방이면 테두리를 초록색으로, 아니면 기본 회색
                      final isJoined = (_joinedRoomId != null && _joinedRoomId == roomId);

                      return GestureDetector(
                        onTap: () => _enterDetail(index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isJoined
                                  ? Colors.green
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.room,
                                size: 40,
                                color: isJoined ? Colors.green : Colors.blue,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 방 제목
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isJoined ? Colors.green : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // 거리 정보만 표시
                                    Text(
                                      '거리: ${distance.toStringAsFixed(1)}km',
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