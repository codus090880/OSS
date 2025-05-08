import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // add flutter_spinkit to pubspec.yaml
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/button_box.dart';

class MatchingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // no AppBar
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(height: 100),

            // 타이틀 텍스트
            Text(
              '러닝 메이트를 찾고 있어요!',
              style: TextStyle(
                color: Colors.black,
                fontSize: 32,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 50),

            SpinKitCircle(
              color: Colors.black,
              size: 60.0,
            ),

            Spacer(),


            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: ButtonBox(
                text: '취소하기',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),


      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          const routes = ['/home', '/running', '/profile'];
          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/running');
          } else {
            Navigator.pushReplacementNamed(context, routes[index]);
          }
        },
      ),
    );
  }
}
