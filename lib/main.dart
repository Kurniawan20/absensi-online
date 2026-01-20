import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bloc/login/login_bloc.dart';

import 'repository/login_repository.dart';
import 'bloc/presence/presence_bloc.dart';
import 'repository/presence_repository.dart';
import 'bloc/home/home_bloc.dart';
import 'repository/home_repository.dart';
import 'bloc/attendance_recap/attendance_recap_bloc.dart';
import 'repository/attendance_recap_repository.dart';
import 'bloc/notification/notification_bloc.dart';
import 'bloc/notification/notification_event.dart';
import 'repository/notification_repository.dart';
import 'bloc/leave/leave_bloc.dart';
import 'repository/leave_repository.dart';

import 'screens/page_splashscreen.dart';
import 'firebase_options.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final loginRepository = LoginRepository();
  final presenceRepository = PresenceRepository();
  final homeRepository = HomeRepository();
  final attendanceRecapRepository = AttendanceRecapRepository();
  final notificationRepository = NotificationRepository(preferences: prefs);
  final leaveRepository = LeaveRepository();

  runApp(
    MyApp(
      loginRepository: loginRepository,
      presenceRepository: presenceRepository,
      homeRepository: homeRepository,
      attendanceRecapRepository: attendanceRecapRepository,
      notificationRepository: notificationRepository,
      leaveRepository: leaveRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  final LoginRepository loginRepository;
  final PresenceRepository presenceRepository;
  final HomeRepository homeRepository;
  final AttendanceRecapRepository attendanceRecapRepository;
  final NotificationRepository notificationRepository;
  final LeaveRepository leaveRepository;

  const MyApp({
    Key? key,
    required this.loginRepository,
    required this.presenceRepository,
    required this.homeRepository,
    required this.attendanceRecapRepository,
    required this.notificationRepository,
    required this.leaveRepository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => LoginBloc(loginRepository: loginRepository),
        ),
        BlocProvider(
          create: (context) =>
              PresenceBloc(presenceRepository: presenceRepository),
        ),
        BlocProvider(
          create: (context) => HomeBloc(homeRepository: homeRepository),
        ),
        BlocProvider(
          create: (context) =>
              AttendanceRecapBloc(repository: attendanceRecapRepository),
        ),
        BlocProvider(
          create: (context) {
            final bloc = NotificationBloc(
              notificationRepository: notificationRepository,
            );
            bloc.add(InitializeNotifications());
            return bloc;
          },
        ),
        BlocProvider(
          create: (context) => LeaveBloc(leaveRepository: leaveRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Monitoring Project',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('id', 'ID'),
          Locale('en', 'US'),
        ],
        theme: ThemeData(
          primaryColor: const Color.fromRGBO(1, 101, 65, 1),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromRGBO(1, 101, 65, 1),
          ),
          inputDecorationTheme: InputDecorationTheme(
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            floatingLabelStyle: const TextStyle(
              color: Color.fromRGBO(1, 101, 65, 1),
            ),
            labelStyle: TextStyle(color: Colors.grey[600]),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 25,
            ),
            border: InputBorder.none,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF016541),
            elevation: 0,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
