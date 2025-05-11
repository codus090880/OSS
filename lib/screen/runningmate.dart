import 'package:flutter/material.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/screen/add_runningmate.dart';


class RunningMate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(
          title: '러닝 메이트',
          onRightPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddRunningmate()),
            );
          },
          rightIcon: Icons.person_add,
        ),
      ),

      body: Center(
        child: Text(
          '러닝 메이트 메인 화면',
          style: TextStyle(fontSize: 18, color: Colors.black),
        ),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(
          currentIndex: 3,
          onTap: (index) {
            const routes = ['/home', '/running', '/course', '/profile'];
            if (index == 3) {
              Navigator.pushReplacementNamed(context, '/profile');
            } else {
              Navigator.pushReplacementNamed(context, routes[index]);
            }
          },
        ),
      ),
    );
  }
}