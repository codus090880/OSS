import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:prunners/screen/agree_screen.dart';
import 'package:prunners/screen/chat_detail_screen.dart';
import 'package:prunners/screen/course_notify_screen.dart';
import 'package:prunners/screen/course_recommended_screen.dart';
import 'package:prunners/screen/course_screen.dart';
import 'package:prunners/screen/delete_account_screen.dart';
import 'package:prunners/screen/evaluate_screen.dart';
import 'package:prunners/screen/home_screen.dart';
import 'package:prunners/screen/level_guide_screen.dart';
import 'package:prunners/screen/login_screen.dart';
import 'package:prunners/screen/match_failed_screen.dart';
import 'package:prunners/screen/matching_list_screen.dart';
import 'package:prunners/screen/mate_notify_screen.dart';
import 'package:prunners/screen/profile_screen.dart';
import 'package:prunners/screen/read_review_screen.dart';
import 'package:prunners/screen/reset_password_screen.dart';
import 'package:prunners/screen/matching_term_screen.dart';
import 'package:prunners/screen/runningtype_select_screen.dart';
import 'package:prunners/screen/signup_screen.dart';
import 'package:prunners/screen/term_of_use_screen.dart';
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
import 'package:prunners/model/push.dart';
import 'package:prunners/model/auth_service.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:prunners/model/local_manager.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  AuthRepository.initialize(
    appKey: dotenv.env['KAKAO_JS_KEY']!,
  );
  await initializeDateFormatting('ko_KR', null);
  //await LocalManager.initialize();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
  await PushNotificationService.initialize();
  AuthService.setupInterceptor();

  final prefs = await SharedPreferences.getInstance();
  final enabled = prefs.getBool('pushEnabled') ?? false;

  if (enabled) {
    await PushNotificationService.scheduleDailyFixed(
      id: 1,
      title: '상쾌한 아침입니다.',
      body: '러닝 어떠신가요?',
      hour: 7,
      minute: 00,
      payload: 'morning_greeting',
    );

    final lastDateStr = prefs.getString('lastWeatherCheckDate');
    final todayStr = DateTime.now().toString().split(' ')[0];

    if (lastDateStr != todayStr) {
      final apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';
      if (apiKey.isNotEmpty) {
        await PushNotificationService.fetchWeatherAndNotify(apiKey);
        await prefs.setString('lastWeatherCheckDate', todayStr);
      }
    }
  }

  final isLoggedIn = await AuthService.isLoggedIn();
  runApp(MyApp(loggedIn: isLoggedIn));
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
        '/setting': (_) => Setting(),
        '/matching': (_) => MatchingScreen(),
        '/record': (_) => RecordScreen(),
        '/after_matching' : (_) => AfterMatching(),
        '/user_set' : (_) => ProfileScreen(),
        '/badge': (_) => BadgeScreen(),
        '/course': (_) => CourseRecommendedScreen(),
        '/addrunningmate': (_) => AddRunningmate(),
        '/runningscreen' : (_) => RunningScreen(),
        '/levelguide': (_) => LevelGuideScreen(),
        '/reset': (_) => ResetPasswordScreen(),
        '/mate_notify': (_) => MateNotifyScreen(),
        '/delete_account': (_) => DeleteAccountScreen(),
        '/matching_list': (_) => MatchingListScreen(),
        '/matching_term': (_) => MatchingTermScreen(),
        '/term_of_use': (_) => TermOfUseScreen(),
        '/matching_failed': (_) => MatchingFailedScreen(),
      },
    );
  }
}