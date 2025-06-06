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

  /// 내가 이미 참여한 채팅방 ID들 (없으면 빈 리스트)
  List<int> _joinedRoomIds = [];

  bool _loadingRooms = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 공개 채팅방 목록과 내가 참여한 방 ID들을 동시에 가져옵니다.
    _fetchPublicRooms();
    _fetchMyRooms();
  }

  /// 1) 공개 채팅방 목록 조회
  Future<void> _fetchPublicRooms() async {
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
        _publicRooms = [];
      });
    } catch (e) {
      setState(() {
        _loadingRooms = false;
        _errorMessage = '알 수 없는 오류가 발생했습니다.';
        _publicRooms = [];
      });
    }
  }

  /// 2) 내가 이미 참여한 채팅방 ID들 조회
  Future<void> _fetchMyRooms() async {
    try {
      // 서버가 List<dynamic> 형태로 room 객체 목록을 반환한다고 가정
      final response = await AuthService.dio.get<List<dynamic>>(
        '/chatrooms/my/',
      );

      // raw data 확인용 디버깅
      debugPrint('[/chatrooms/my/] 성공: statusCode=${response.statusCode}');
      debugPrint('[/chatrooms/my/] raw data=${response.data}');

      final List<dynamic> dataList = response.data ?? [];

      if (dataList.isNotEmpty) {
        // 각 요소를 Map<String, dynamic>으로 간주하여 room_id 목록 생성
        final ids = dataList
            .whereType<Map<String, dynamic>>()
            .map((e) => e['room_id'] as int)
            .toList();
        debugPrint('추출된 room_id들: $ids');

        setState(() {
          _joinedRoomIds = ids;
        });
      } else {
        setState(() {
          _joinedRoomIds = [];
        });
        debugPrint('[/chatrooms/my/] 데이터가 비어 있습니다.');
      }
    } on DioError catch (err) {
      debugPrint('=== DioError 발생 (/chatrooms/my/) ===');
      debugPrint('  .type           : ${err.type}');
      debugPrint('  .message        : ${err.message}');
      debugPrint('  .error          : ${err.error}');
      debugPrint('  .statusCode     : ${err.response?.statusCode}');
      debugPrint('  .response data  : ${err.response?.data}');
      debugPrint('  .requestOptions.uri    : ${err.requestOptions.uri}');
      debugPrint('  .requestOptions.method : ${err.requestOptions.method}');
      debugPrint('  .requestOptions.headers: ${err.requestOptions.headers}');
      setState(() {
        _joinedRoomIds = [];
      });
    } catch (e) {
      debugPrint('=== 예외 발생 (/chatrooms/my/) ===');
      debugPrint('  error: $e');
      setState(() {
        _joinedRoomIds = [];
      });
    }
  }

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

    final sortedRooms = [
      ..._publicRooms.where((r) => _joinedRoomIds.contains(r['room_id'] as int)),
      ..._publicRooms.where((r) => !_joinedRoomIds.contains(r['room_id'] as int)),
    ];

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
                    itemCount: sortedRooms.length,
                    itemBuilder: (context, index) {
                      final room = sortedRooms[index];
                      final title = room['title'] as String? ?? '(제목 없음)';
                      final distance = room['distance_km'] as num? ?? 0;
                      final roomId = room['room_id'] as int;

                      // 내가 속한 방이면 초록색, 아니면 기본 회색
                      final isJoined = _joinedRoomIds.contains(roomId);

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(roomId: roomId),
                            ),
                          );
                        },
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
                                        color: isJoined
                                            ? Colors.green
                                            : Colors.black,
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