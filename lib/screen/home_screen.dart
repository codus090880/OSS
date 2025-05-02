import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/rounded_shadow_box.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomeBody(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;
          Navigator.pushReplacementNamed(context, ['/home', '/running', '/profile'][index]);
        },
      ),
    );
  }
}

class HomeBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = DateFormat.M('ko_KR').format(now);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TopBar(),

          SizedBox(height: 25),

          /// 상단 박스
          RoundedShadowBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '마라톤 도전해봐요!',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Text(
                  '${currentMonth}',
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
                SizedBox(height: 20),
                RoundedShadowBox(
                  height: 80,
                  width: double.infinity,
                  padding: EdgeInsets.zero,
                  child: Center(child: Text('항목 1')),
                ),
                SizedBox(height: 10),
                RoundedShadowBox(
                  height: 80,
                  width: double.infinity,
                  padding: EdgeInsets.zero,
                  child: Center(child: Text('항목 2')),
                ),
                SizedBox(height: 20),
                Center(
                  child: RoundedShadowBox(
                    height: 38,
                    width: 150,
                    padding: EdgeInsets.zero,
                    child: Center(
                      child: Text(
                        '더보기 +',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          /// 하단 박스
          RoundedShadowBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('최근 인기있는 코스', style: TextStyle(fontSize: 16, color: Colors.black)),
                SizedBox(height: 10),
                Text('리뷰 보기', style: TextStyle(fontSize: 16, color: Colors.black)),
              ],
            ),
          ),

          SizedBox(height: 50),
        ],
      ),
    );
  }
}


