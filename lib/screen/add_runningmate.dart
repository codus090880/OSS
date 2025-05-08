import 'package:flutter/material.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/grey_box.dart';
import 'package:prunners/widget/rounded_shadow_box.dart';
import 'package:prunners/widget/bottom_bar.dart';

class AddRunningmate extends StatefulWidget {
  @override
  _AddRunningmate createState() => _AddRunningmate();
}

class _AddRunningmate extends State<AddRunningmate> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() => _controller.clear();

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(title: '친구 등록'),
      ),

      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 검색 입력창
            GreyBox(
              child: Row(
                children: [
                  Icon(Icons.search, color: Color(0xFF8390A1)),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                      decoration: InputDecoration(
                        hintText: '닉네임',
                        hintStyle: TextStyle(
                          color: Color(0xFF8390A1),
                          fontSize: 15,
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                  if (hasText)
                    IconButton(
                      icon: Icon(Icons.cancel, size: 20, color: Colors.grey),
                      onPressed: _clear,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                    ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // 검색 결과 자리
            RoundedShadowBox(
              height: 78,
              width: double.infinity,
              child: Center(
                child: Text(
                  '// 검색 결과 표시 영역',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ),


          ],
        ),
      ),

      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          const routes = ['/home', '/running', '/profile'];
          if (index == 2) {
            Navigator.pushReplacementNamed(context, '/profile');
          } else {
            Navigator.pushReplacementNamed(context, routes[index]);
          }
        },
      ),
    );
  }
}