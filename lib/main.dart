import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:strife/data/repositories/chat_repository.dart';
import 'package:strife/data/repositories/user_repository.dart';
import 'package:strife/data/repositories/vcs_repository.dart';

// Импорты слоев
import 'package:strife/firebase/firebase_options.dart';
import 'package:strife/presentation/blocs/contacts/contacts_bloc.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/data/repositories/auth_repository.dart';
import 'package:strife/ui/view_models/auth_view_model.dart';

// Импорты экранов
import 'package:strife/ui/views/login/login_view.dart';
import 'package:strife/ui/views/home/home_view.dart';

// Создаем плагин
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Канал для Android
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description: 'Этот канал используется для важных уведомлений.', // description
  importance: Importance.max,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupNotifications();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => AuthRepository()),
        Provider(create: (_) => ChatRepository()),
        Provider(create: (_) => UserRepository()),
        Provider(create: (_) => VCSRepository()),

        // ViewModels
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ContactsBloc(context.read<UserRepository>()),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        extensions: const [
          GradientTheme(
            mainGradient: LinearGradient(
              colors: [Color(0xFFB91ED0), Color(0xFF5E0F6A)],
            ),
          ),
        ],
        brightness: Brightness.light,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const HomeView(); // Пользователь залогинен
          }

          return LoginView(); // Пользователь не залогинен
        },
      ),
    );
  }
}

Future<void> setupNotifications() async {
  // Запрос разрешений для Android
  await FirebaseMessaging.instance.requestPermission();

  // Создаем канал на устройстве
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // Настройка инициализации для Android
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  await flutterLocalNotificationsPlugin.initialize(
    settings: const InitializationSettings(
      android: initializationSettingsAndroid,
    ),
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: android.smallIcon,
          ),
        ),
      );
    }
  });
}
