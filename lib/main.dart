import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:prunners/screen/home_screen.dart';
import 'package:prunners/screen/login_screen.dart';
import 'package:prunners/screen/userpage_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
      initialRoute: '/login',
      routes: {
        '/login': (_) => LoginScreen(),
        '/home': (_) => HomeScreen(),
        //'/running': (_) => RunningScreen(),
        '/profile': (_) => UserPageScreen(),
      },
      home: HomeScreen(),
    );
  }
}