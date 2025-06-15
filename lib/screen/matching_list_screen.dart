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
    _fetchPublicRooms().whenComplete(() {
      // 2) 공개 방 로드가 끝나면 내 방을 불러와서 _publicRooms에 병합
      _fetchMyRooms();
    });
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

      debugPrint('🔍 [_fetchPublicRooms] statusCode: ${response.statusCode}');
      debugPrint('🔍 [_fetchPublicRooms] raw response.data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null) {
          debugPrint('🔍 [_fetchPublicRooms] data type: ${data.runtimeType}');
          debugPrint('🔍 [_fetchPublicRooms] data length: ${data.length}');

          // 각 항목 상세 확인
          for (int i = 0; i < data.length; i++) {
            debugPrint('🔍 [_fetchPublicRooms] item[$i]: ${data[i]}');
          }

          final rooms = data
              .whereType<Map<String, dynamic>>()
              .map((item) => {
            'room_id': item['room_id'],
            'title': item['title'],
            'distance_km': item['distance_km'],
          })
              .toList();

          debugPrint('🔍 [_fetchPublicRooms] parsed rooms: $rooms');

          final unique = <int>{};
          final deduped = <Map<String, dynamic>>[];
          for (var r in rooms) {
            final id = r['room_id'] as int;
            debugPrint('🔍 [_fetchPublicRooms] processing room_id: $id');
            if (unique.add(id)) {
              deduped.add(r);
              debugPrint('🔍 [_fetchPublicRooms] added room_id: $id');
            } else {
              debugPrint('🔍 [_fetchPublicRooms] duplicate room_id: $id');
            }
          }

          debugPrint('🔍 [_fetchPublicRooms] final deduped rooms: $deduped');

          setState(() {
            _publicRooms = deduped;
            _loadingRooms = false;
          });
        } else {
          debugPrint('🔍 [_fetchPublicRooms] data is null');
          setState(() {
            _publicRooms = [];
            _loadingRooms = false;
          });
        }
      } else {
        debugPrint('🔍 [_fetchPublicRooms] non-200 status: ${response.statusCode}');
        setState(() {
          _errorMessage =
          '상태 코드 ${response.statusCode}로 방 목록을 가져오지 못했습니다.';
          _loadingRooms = false;
        });
      }
    } on DioError catch (err) {
      debugPrint('🔍 [_fetchPublicRooms] DioError: ${err.response?.statusCode}');
      debugPrint('🔍 [_fetchPublicRooms] DioError data: ${err.response?.data}');

      String message;
      if (err.response?.statusCode == 400) {
        message = '현재 주변에 공개 채팅방이 없습니다.';
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
      debugPrint('🔍 [_fetchPublicRooms] Exception: $e');
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
      final response = await AuthService.dio.get<List<dynamic>>(
        '/chatrooms/my/',
      );
      debugPrint('[/chatrooms/my/] statusCode=${response.statusCode}');

      final dataList = response.data ?? [];

      if (dataList.isNotEmpty) {
        // 1) room_id 리스트 추출
        final ids = dataList
            .whereType<Map<String, dynamic>>()
            .map((e) => e['room_id'] as int)
            .toList();
        debugPrint('추출된 room_id들: $ids');

        // 2) _publicRooms에 없는 내 방 추가 (distance_km는 0.0으로 임시 설정)
        for (var item in dataList.whereType<Map<String, dynamic>>()) {
          // 디버깅: item 전체 확인
          debugPrint('🔍 fetchMyRooms item: $item');

          final id = item['room_id'] as int;

          // 디버깅: title 필드 확인
          final rawTitle = item['title'];
          debugPrint('🔍 raw title value: $rawTitle (type=${rawTitle.runtimeType})');

          final title = (rawTitle as String?) ?? '나의 채팅방';
          debugPrint('🔍 parsed title: $title');

          if (!_publicRooms.any((r) => r['room_id'] == id)) {
            _publicRooms.add({
              'room_id': id,
              'title': title,
              'distance_km': 0.0,
            });
            // 디버깅: 추가 후 publicRooms 상태
            debugPrint('🔍 _publicRooms updated: ${_publicRooms.last}');
          }
        } debugPrint('[/chatrooms/my/] raw data=${response.data}');


        setState(() {
          _joinedRoomIds = ids;
        });
      } else {
        debugPrint('[/chatrooms/my/] 데이터가 비어 있습니다.');
        setState(() {
          _joinedRoomIds = [];
        });
      }
    } on DioError catch (err) {
      debugPrint('=== DioError (/chatrooms/my/) ===\n'
          'status: ${err.response?.statusCode}\n'
          'data: ${err.response?.data}');
      setState(() {
        _joinedRoomIds = [];
      });
    } catch (e) {
      debugPrint('=== 예외 (/chatrooms/my/) ===\nerror: $e');
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