import 'package:flutter/material.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/widget/rounded_shadow_box.dart';

class UserPageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: UserBody(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 2) return;
          Navigator.pushReplacementNamed(context, ['/home', '/running', '/profile'][index]);
        },
      ),
    );
  }
}

class UserBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                height: 90,
                child: RoundedShadowBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('최근 인기있는 코스', style: TextStyle(fontSize: 16, color: Colors.black)),
                      SizedBox(height: 10),
                      Text('리뷰 보기', style: TextStyle(fontSize: 16, color: Colors.black)),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 90,
                child: RoundedShadowBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('최근 인기있는 코스', style: TextStyle(fontSize: 16, color: Colors.black)),
                      SizedBox(height: 10),
                      Text('리뷰 보기', style: TextStyle(fontSize: 16, color: Colors.black)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


