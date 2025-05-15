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
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double bottomPadding = 8.0;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        20,
        statusBarHeight + 8,
        20,
        bottomPadding,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, size: 28),
            onPressed: () => Navigator.pop(context),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
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
          if (rightIcon != null && onRightPressed != null)
            IconButton(
              icon: Icon(rightIcon, size: 28),
              onPressed: onRightPressed,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            )
          else
            SizedBox(width: 48),
        ],
      ),
    );
  }

  @override
  Size get preferredSize {

    final double statusBarHeight =
        WidgetsBinding.instance.window.padding.top /
            WidgetsBinding.instance.window.devicePixelRatio;
    final double totalHeight =
        statusBarHeight + 72;
    return Size.fromHeight(totalHeight);
  }
}

