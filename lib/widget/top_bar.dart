import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 7, 20, 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'P-RUNNERS',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 30,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        )
    );
  }
}

class CustomTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData? rightIcon;
  final VoidCallback? onRightPressed;

  const CustomTopBar({
    Key? key,
    required this.title,
    this.rightIcon,
    this.onRightPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 50, 20, 7),
      color: Colors.white,
      child: Row(
        children: [
          // 좌측 뒤로가기
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black, size: 28),
            onPressed: () => Navigator.pop(context),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),

          // 가운데 타이틀
          Expanded(
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 25,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // 우측 아이콘이 넘어왔을 때만 렌더링
          if (rightIcon != null && onRightPressed != null)
            IconButton(
              icon: Icon(rightIcon, color: Colors.black, size: 28),
              onPressed: onRightPressed,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
            )
          else
            SizedBox(width: 48),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(60);
}