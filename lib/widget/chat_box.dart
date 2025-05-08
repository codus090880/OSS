import 'package:flutter/material.dart';

class ChatBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatBox({
    Key? key,
    required this.controller,
    required this.onSend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(

      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Row(
        children: [

          Container(
            width: 42,
            height: 42,
            decoration: ShapeDecoration(
              color: Colors.white.withAlpha(26),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.add, size: 24, color: Colors.black54),
              onPressed: () {
                // TODO: 이미지 첨부 기능
              },
            ),
          ),

          const SizedBox(width: 12),

          // 가변 너비 입력창
          Expanded(
            child: Container(
              constraints: BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: ShapeDecoration(
                color: const Color(0xFFF0F0F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: '메시지 입력',
                        hintStyle: TextStyle(
                          color: const Color(0xFF0D1217).withOpacity(0.3),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 오른쪽 전송 버튼
          Container(
            width: 42,
            height: 42,
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.black54),
              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }
}