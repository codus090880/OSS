import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:prunners/widget/outlined_button_box.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/model/auth_service.dart';
import 'package:prunners/model/local_manager.dart';
import 'package:prunners/screen/mate_notify_screen.dart';

/// 1) 모델에 닉네임과 roomId 외에 avatarUrl 추가
class MateEvaluationTarget {
  final String nickname;
  final int roomId;
  final String? avatarUrl; // 새로 추가

  MateEvaluationTarget({
    required this.nickname,
    required this.roomId,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'room_id': roomId,
    };
  }
}

class EvaluateScreen extends StatefulWidget {
  final int roomId;
  final int sessionId;
  const EvaluateScreen({super.key, required this.roomId, required this.sessionId,});

  @override
  State<EvaluateScreen> createState() => _EvaluateScreenState();
}

class _EvaluateScreenState extends State<EvaluateScreen> {
  List<MateEvaluationTarget> mates = [];
  bool isLoading = true;
  bool isPositive = true;

  List<String> selectedReasons = [];
  int currentIndex = 0;
  PageController _pageController = PageController();
  MateEvaluationTarget get currentMate => mates[currentIndex];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
  void initState() {
    super.initState();
    AuthService.setupInterceptor();
    fetchMates();
  }

  Future<void> fetchMates() async {
    try {
      // 디버깅: 호출 직전 URL과 roomId 확인
      debugPrint('→ fetchMates 호출: /rooms/${widget.roomId}/user_list/');

      // 서버에서 List<dynamic> 형태로 닉네임 + avatarUrl 목록을 받음
      final response = await AuthService.dio.get<List<dynamic>>(
        '/rooms/${widget.roomId}/user_list/',
      );

      // 디버깅: 응답 상태코드와 전체 데이터
      debugPrint(
          '[/rooms/${widget.roomId}/user_list/] status: ${response.statusCode}');
      debugPrint(
          '[/rooms/${widget.roomId}/user_list/] raw data: ${response.data}');

      final List<dynamic>? dataList = response.data;
      if (response.statusCode == 200 && dataList != null) {
        // 로컬에 저장된 내 닉네임 조회
        final myNick = await LocalManager.getNickname();
        debugPrint('내 닉네임: $myNick');

        List<MateEvaluationTarget> loaded = [];
        for (final item in dataList) {
          if (item is Map<String, dynamic> && item['nickname'] is String) {
            final nickname = item['nickname'] as String;
            // 내 닉네임이면 평가 대상에서 제외
            if (nickname == myNick) {
              debugPrint('내 닉네임 "$nickname" 은(는) 평가 대상에서 제외합니다.');
              continue;
            }
            // avatarUrl이 String 또는 null인 경우를 처리
            final avatar = item['avatarUrl'] is String
                ? item['avatarUrl'] as String
                : null;

            loaded.add(MateEvaluationTarget(
              nickname: nickname,
              roomId: widget.roomId,
              avatarUrl: avatar,
            ));
          } else {
            debugPrint('fetchMates: 요소 형식이 기대와 다릅니다: $item');
          }
        }

        setState(() {
          mates = loaded;
          isLoading = false;
        });
      } else {
        debugPrint(
            'fetchMates: 빈 데이터이거나 statusCode != 200 (dataList=$dataList)');
        throw Exception('서버 응답 오류');
      }
    } on DioError catch (err) {
      // 디버깅: DioError 상세
      debugPrint(
          '=== DioError 발생 (/rooms/${widget.roomId}/user_list/) ===');
      debugPrint('  .type           : ${err.type}');
      debugPrint('  .message        : ${err.message}');
      debugPrint('  .error          : ${err.error}');
      debugPrint('  .statusCode     : ${err.response?.statusCode}');
      debugPrint('  .response data  : ${err.response?.data}');
      debugPrint('  .requestOptions.uri    : ${err.requestOptions.uri}');
      debugPrint('  .requestOptions.method : ${err.requestOptions.method}');
      debugPrint('  .requestOptions.headers: ${err.requestOptions.headers}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            '메이트 목록 불러오기 실패: ${err.response?.statusCode}')),
      );
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      // 기타 예외
      debugPrint(
          '=== 예외 발생 (/rooms/${widget.roomId}/user_list/) ===');
      debugPrint('  error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('메이트 목록 불러오기 실패: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> submitEvaluation() async {
    if (selectedReasons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사유를 한 가지 이상 선택해주세요')),
      );
      return;
    }

    try {
      final evaluator = await LocalManager.getNickname();

      // 디버깅: 요청 바디 찍기
      final body = {
        'target': currentMate.nickname,
        'evaluator': evaluator,
        'session_id': widget.sessionId,
        'reasons': selectedReasons,
        'score': isPositive ? 1 : -1,
      };
      debugPrint('→ POST /evaluate/ 요청 바디: $body');

      final response = await AuthService.dio.post<Map<String, dynamic>>(
        '/evaluate/',
        data: body,
        options: Options(contentType: Headers.jsonContentType),
      );

      // 디버깅: 응답 상태와 데이터 찍기
      debugPrint('← 응답 status=${response.statusCode}, data=${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (currentIndex < mates.length - 1) {
          setState(() {
            currentIndex += 1;
            selectedReasons.clear();
            isPositive = true;
          });
          _pageController.animateToPage(
            currentIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('모든 메이트 평가가 완료되었습니다')),
          );
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('평가 실패: ${response.statusCode}')),
        );
      }
    } on DioError catch (err) {
      // 디버깅: DioError 상세 정보
      debugPrint('=== DioError 발생 (/evaluate/) ===');
      debugPrint('  .type           : ${err.type}');
      debugPrint('  .message        : ${err.message}');
      debugPrint('  .error          : ${err.error}');
      debugPrint('  .statusCode     : ${err.response?.statusCode}');
      debugPrint('  .response data  : ${err.response?.data}');
      debugPrint('  .requestOptions.uri    : ${err.requestOptions.uri}');
      debugPrint('  .requestOptions.method : ${err.requestOptions.method}');
      debugPrint('  .requestOptions.data   : ${err.requestOptions.data}');
      debugPrint('  .requestOptions.headers: ${err.requestOptions.headers}');

      String userMsg = '평가 중 오류가 발생했습니다.';
      if (err.response?.statusCode == 400) {
        userMsg = '400: 요청 데이터 형식 오류 또는 필수값 누락';
      } else if (err.response?.statusCode == 403) {
        userMsg = '403: 권한이 없습니다.';
      } else if (err.response?.statusCode == 500) {
        userMsg = '500: 서버 내부 오류';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userMsg)),
      );
    } catch (e) {
      debugPrint('=== 예외 발생 (/evaluate/) ===\n  error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (mates.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('러닝 메이트')),
        body: const Center(child: Text('평가할 메이트가 없습니다')),
      );
    }

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
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MateNotifyScreen(targetNickname: currentMate.nickname,
                      roomid: currentMate.roomId,)),
              );
            },
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.black,
              size: 32,
            ),
          )
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) return;
            Navigator.pushReplacementNamed(
              context,
              ['/home', '/running', '/profile'][index],
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
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
              SizedBox(
                height: 240, // 약간 높이 추가
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: mates.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentIndex = index;
                      selectedReasons.clear();
                      isPositive = true;
                    });
                  },
                  itemBuilder: (context, index) {
                    final mate = mates[index];
                    return Column(
                      children: [
                        // ─── avatarUrl이 있으면 네트워크 이미지를, 없으면 기본 아이콘 ───
                        if (mate.avatarUrl != null &&
                            mate.avatarUrl!.isNotEmpty)
                          CircleAvatar(
                            radius: 60,
                            backgroundImage:
                            NetworkImage(mate.avatarUrl!),
                          )
                        else
                          const Icon(
                            Icons.account_circle,
                            size: 120,
                            color: Color(0xFFE0E0E0),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          mate.nickname,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
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
                final isSelected =
                selectedReasons.contains(reason);
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
                      minimumSize: const Size.fromHeight(55),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
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
                onPressed: submitEvaluation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
