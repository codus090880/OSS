import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/button_box.dart';
import 'package:prunners/model/auth_service.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({Key? key}) : super(key: key);

  @override
  _MatchingScreenState createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  bool _isRequesting = true;   // 매칭 요청 중인지 여부
  String? _errorMessage;       // 에러 발생 시 보여줄 메시지

  @override
  void initState() {
    super.initState();
    // 화면이 로드되면 즉시 매칭 요청 시작
    _startMatchRequest();
  }

  Future<void> _startMatchRequest() async {
    try {
      final response = await AuthService.dio.post('/match/start/');

      if (response.statusCode == 200) {
        final result = response.data;
        print('매칭 결과: $result');

        if (result['matched'] == true) {
          // 매칭 성공 → 채팅방으로 바로 이동
          Navigator.pushReplacementNamed(
            context,
            '/chatroom',
            arguments: {
              'room_id': result['room_id'],
              'room_name': result['room_name'],
              'is_public': result['is_public'],
            },
          );
          return;
        } else {
          // ★ 변경: 대기열에 등록만 된 상태에서도 _isRequesting 유지 → 계속 로딩바 표시
          debugPrint('🟢 매칭 대기열에 등록됨, 계속 로딩바 표시');
          // 기존 setState는 제거되었습니다:
          // setState(() {
          //   _isRequesting = false;
          //   _errorMessage = '매칭 대기열에 등록되었습니다. 잠시만 기다려주세요.';
          // });
        }
      } else {
        setState(() {
          _isRequesting = false;
          _errorMessage = '매칭 요청 실패: ${response.statusCode}';
        });
      }
    } on DioError catch (err) {
      // 400 등 서버에서 에러코드를 보냈을 때
      String message;
      if (err.response?.statusCode == 400) {
        message = '[400] 대기열에 이미 참여 중입니다.';
      } else {
        message = '매칭 요청 중 네트워크 오류가 발생했습니다.';
      }
      setState(() {
        _isRequesting = false;
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _isRequesting = false;
        _errorMessage = '알 수 없는 오류가 발생했습니다.';
      });
    }
  }

  Future<bool> _onWillPop() async {
    // 매칭 요청이 아직 진행 중이면 뒤로가기 막기
    if (_isRequesting) {
      return false;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('매칭을 취소하시겠습니까?'),
          actions: [
            TextButton(
              child: const Text('아니오'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('예'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (shouldCancel == true) {
      try {
        final response = await AuthService.dio.post('/match/cancel/');
        final message = response.data['message'] as String? ?? '취소되었습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } on DioError catch (err) {
        if (err.response?.statusCode == 400) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('대기열에 참여 중이지 않습니다.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('오류가 발생했습니다. 잠시 후 다시 시도해주세요.')),
          );
        }
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('오류가 발생했습니다.')),
        );
      }
      // true 반환 → 뒤로 가기
      return true;
    }

    // false 반환 → 화면 유지
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 100),
              const Text(
                '러닝 메이트를 찾고 있어요!',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 32,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 50),

              // 요청 중일 때는 스피너, 아니면 상태 메시지 보여주기
              if (_isRequesting) ...[
                const SpinKitCircle(
                  color: Colors.black,
                  size: 60.0,
                ),
              ] else ...[
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ),
              ],

              const Spacer(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: ButtonBox(
                  text: _isRequesting ? '취소하기' : '뒤로 가기',
                  onPressed: () async {
                    if (_isRequesting) {
                      // 요청 중일 때 버튼 눌리면 곧바로 취소 API 호출
                      try {
                        final response = await AuthService.dio.post('/match/cancel/');
                        final message = response.data['message'] as String? ?? '취소되었습니다.';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      } on DioError catch (err) {
                        if (err.response?.statusCode == 400) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('대기열에 참여 중이지 않습니다.')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('오류가 발생했습니다. 잠시 후 다시 시도해주세요.')),
                          );
                        }
                      } catch (_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('오류가 발생했습니다.')),
                        );
                      }
                      Navigator.pop(context);
                    } else {
                      Navigator.pop(context);
                    }
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
              const routes = ['/home', '/running', '/course', '/profile'];
              if (index == 1) {
                Navigator.pushReplacementNamed(context, '/running');
              } else {
                Navigator.pushReplacementNamed(context, routes[index]);
              }
            },
          ),
        ),
      ),
    );
  }
}
