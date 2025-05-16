import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:prunners/screen/agree_screen.dart';
import 'package:prunners/screen/alone_screen.dart';
import 'package:prunners/screen/course_recommended_screen.dart';
import 'package:prunners/screen/course_screen.dart';
import 'package:prunners/screen/evaluate_screen.dart';
import 'package:prunners/screen/home_screen.dart';
import 'package:prunners/screen/login_screen.dart';
import 'package:prunners/screen/profile_screen.dart';
import 'package:prunners/screen/read_review_screen.dart';
import 'package:prunners/screen/runningtype_select_screen.dart';
import 'package:prunners/screen/signup_screen.dart';
import 'package:prunners/screen/together_screen.dart';
import 'package:prunners/screen/userpage_screen.dart';
import 'package:prunners/screen/write_review_screen.dart';
import 'package:prunners/screen/setting.dart';
import 'package:prunners/screen/matching_screen.dart';
import 'package:prunners/screen/record_screen.dart';
import 'package:prunners/screen/after_matching.dart';
import 'package:prunners/screen/running_screen.dart';
import 'package:prunners/screen/chat_screen.dart';
import 'package:prunners/screen/badge_screen.dart';
import 'package:prunners/screen/add_runningmate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:prunners/model/push.dart';
import 'package:prunners/model/auth_service.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AuthRepository.initialize(
    appKey: dotenv.env['KAKAO_JS_KEY']!,
  );
  await initializeDateFormatting('ko_KR', null);
  await PushNotificationService.initialize();
  AuthService.setupInterceptor();

  Workmanager().initialize(callbackDispatcher, isInDebugMode: false,);

  final prefs = await SharedPreferences.getInstance();
  final enabled = prefs.getBool('pushEnabled') ?? false;
  if (enabled) {
    Workmanager().registerOneOffTask(
      'testOnce',
      'weatherTask',
      initialDelay: Duration(seconds: 5),
    );
  }
  final isLoggedIn = await AuthService.isLoggedIn();
  runApp(MyApp(loggedIn: isLoggedIn));
}

Duration _calculateDelayUntil(int hour, int minute) {
  final now = DateTime.now();
  final target = DateTime(now.year, now.month, now.day, hour, minute);
  return now.isAfter(target)
      ? target.add(Duration(days: 1)).difference(now)
      : target.difference(now);
}

class MyApp extends StatelessWidget {
  final bool loggedIn;

  const MyApp({required this.loggedIn, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'P_RUNNERS',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.black,
        ),
        iconTheme: IconThemeData(color: Colors.black),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
        ),
      ),
      initialRoute: loggedIn ? '/home' : '/login',
      routes: {
        '/home': (_) => HomeScreen(),
        '/login': (_) => LoginScreen(),
        '/signup': (_) => SignupScreen(),
        '/agree': (_) => AgreeScreen(),
        '/profile': (_) => UserPageScreen(),
        '/evaluate': (_) => EvaluateScreen(),
        '/running': (_) => RunningtypeSelectScreen(),
        '/alone': (_) => AloneScreen(),
        '/together': (_) => TogetherScreen(),
        '/write': (_) => WriteReviewScreen(),
        '/read': (_) => ReadReviewScreen(),
        '/setting': (_) => Setting(),
        '/matching': (_) => MatchingScreen(),
        '/record': (_) => RecordScreen(),
        '/after_matching' : (_) => AfterMatching(),
        '/chat' : (_) => ChatScreen(),
        '/user_set' : (_) => ProfileScreen(),
        '/badge': (_) => BadgeScreen(),
        '/course': (_) => CourseRecommendedScreen(),
        '/course_detail': (_) => CourseScreen(),
        '/addrunningmate': (_) => AddRunningmate(),
        '/runningscreen' : (_) => RunningScreen(),
      },
    );
  }
}