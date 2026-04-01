import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bloc/login/login_bloc.dart';
import 'services/notification_refresh_service.dart';
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
import 'bloc/app_version/app_version_bloc.dart';
import 'repository/app_version_repository.dart';
import 'bloc/device_reset/device_reset_bloc.dart';
import 'repository/device_reset_repository.dart';
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

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      if (kDebugMode) print('Firebase background: duplicate-app ignored.');
    } else {
      rethrow;
    }
  }
  if (kDebugMode) print('Background message: ');
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      if (kDebugMode) print('Firebase already initialized.');
    } else {
      rethrow;
    }
  }

  await _setupFirebaseMessaging();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    MyApp(
      appVersionRepository: AppVersionRepository(),
      loginRepository: LoginRepository(),
      presenceRepository: PresenceRepository(),
      homeRepository: HomeRepository(),
      attendanceRecapRepository: AttendanceRecapRepository(),
      notificationRepository: NotificationRepository(preferences: prefs),
      leaveRepository: LeaveRepository(),
      deviceResetRepository: DeviceResetRepository(),
    ),
  );
}

Future<void> _setupFirebaseMessaging() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );

  try {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true,
    );
    if (kDebugMode) {
      print('Notification permission: ${settings.authorizationStatus}');
    }

    if (Platform.isIOS) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (kDebugMode) print(apnsToken != null ? 'APNs Token: OK' : 'APNs Token: null');
    }

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );
  } catch (e) {
    if (kDebugMode) print('FCM setup warning: ');
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (kDebugMode) print('Foreground: ');
    NotificationRefreshService().triggerRefresh();
    final notification = message.notification;
    if (notification != null && Platform.isAndroid) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id, channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.high, priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (kDebugMode) print('Notification tapped: ');
    NotificationRefreshService().triggerRefresh();
  });

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null && kDebugMode) {
    print('Opened from terminated state: ');
  }
}

class MyApp extends StatelessWidget {
  final AppVersionRepository appVersionRepository;
  final LoginRepository loginRepository;
  final PresenceRepository presenceRepository;
  final HomeRepository homeRepository;
  final AttendanceRecapRepository attendanceRecapRepository;
  final NotificationRepository notificationRepository;
  final LeaveRepository leaveRepository;
  final DeviceResetRepository deviceResetRepository;

  const MyApp({
    super.key,
    required this.appVersionRepository,
    required this.loginRepository,
    required this.presenceRepository,
    required this.homeRepository,
    required this.attendanceRecapRepository,
    required this.notificationRepository,
    required this.leaveRepository,
    required this.deviceResetRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AppVersionBloc(repository: appVersionRepository)),
        BlocProvider(create: (context) => LoginBloc(loginRepository: loginRepository)),
        BlocProvider(create: (context) => PresenceBloc(presenceRepository: presenceRepository)),
        BlocProvider(create: (context) => HomeBloc(homeRepository: homeRepository)),
        BlocProvider(create: (context) => AttendanceRecapBloc(repository: attendanceRecapRepository)),
        BlocProvider(
          create: (context) {
            final bloc = NotificationBloc(notificationRepository: notificationRepository);
            bloc.add(InitializeNotifications());
            return bloc;
          },
        ),
        BlocProvider(create: (context) => LeaveBloc(leaveRepository: leaveRepository)),
        BlocProvider(create: (context) => DeviceResetBloc(repository: deviceResetRepository)),
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
          colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromRGBO(1, 101, 65, 1)),
          inputDecorationTheme: InputDecorationTheme(
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            floatingLabelStyle: const TextStyle(color: Color.fromRGBO(1, 101, 65, 1)),
            labelStyle: TextStyle(color: Colors.grey[600]),
            contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
            border: InputBorder.none,
          ),
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF016541), elevation: 0),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
