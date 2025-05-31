import 'package:flutter/material.dart';
import 'package:prunners/widget/outlined_button_box.dart';
import 'package:prunners/widget/bottom_bar.dart';

enum RunningType { alone, together }

class RunningtypeSelectScreen extends StatefulWidget {
  const RunningtypeSelectScreen({super.key});

  @override
  State<RunningtypeSelectScreen> createState() => _RunningtypeSelectScreenState();
}

class _RunningtypeSelectScreenState extends State<RunningtypeSelectScreen> {
  RunningType? isSelected;

  void selectType(RunningType type) {
    setState(() {
      isSelected = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAlone = (isSelected == RunningType.alone);
    final isTogether = (isSelected == RunningType.together);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              const Text(
                '오늘은 어떻게 달려볼까요?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: isAlone ? const Color(0xFFE6F3FA) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () => selectType(RunningType.alone),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 350,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isAlone ? Colors.blue : Colors.transparent,
                                width: isAlone ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.directions_run, size: 100, color: Color(0xFFBBDEFB)),
                                SizedBox(height: 10),
                                Text(
                                  '혼자 뛸래요',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '나만의 페이스로 자유롭게',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Material(
                        color: isTogether ? const Color(0xFFE6F3FA) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () => selectType(RunningType.together),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 350,
                            padding: const EdgeInsets.fromLTRB(20, 35, 16, 20),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isTogether ? Colors.deepPurple : Colors.transparent,
                                width: isTogether ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.directions_run, size: 66, color: Color(0xFFB39DDB)),
                                    Transform.translate(
                                      offset: const Offset(-10, 0),
                                      child: Icon(Icons.directions_run, size: 66, color: Color(0xFFB39DDB)),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 32),
                                Text(
                                  '같이 뛸래요',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '러닝 메이트와 함께',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButtonBox(
                text: '다음',
                onPressed: () {
                  if (isAlone) {
                    Navigator.pushNamed(context, '/runningscreen');
                  } else if (isTogether) {
                    Navigator.pushNamed(context, '/matching_list');
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(
          currentIndex: 1,
          onTap: (index) {
            if (index == 1) return;
            Navigator.pushReplacementNamed(
              context,
              ['/home', '/running', '/course', '/profile'][index],
            );
          },
        ),
      ),
    );
  }
}