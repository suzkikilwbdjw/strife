import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:strife/data/repositories/chat_repository.dart';
import 'package:strife/data/repositories/notification_repository.dart';
import 'package:strife/data/repositories/user_repository.dart';
import 'package:strife/data/repositories/vcs_repository.dart';

// Импорты слоев
import 'package:strife/firebase/firebase_options.dart';
import 'package:strife/presentation/blocs/chats/chat_bloc.dart';
import 'package:strife/presentation/blocs/chats/chat_event.dart';
import 'package:strife/presentation/blocs/contacts/contacts_bloc.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/data/repositories/auth_repository.dart';
import 'package:strife/ui/view_models/auth_view_model.dart';
import 'package:strife/ui/views/chat/chat_screen.dart';

// Импорты экранов
import 'package:strife/ui/views/login/login_view.dart';
import 'package:strife/ui/views/home/home_view.dart';
import 'package:strife/ui/views/notifications/notifications_view.dart';

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

// Глобальный ключ навигации
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Настройка уведомлений
  await setupNotifications();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => AuthRepository()),
        Provider(create: (_) => ChatRepository()),
        Provider(create: (_) => UserRepository()),
        Provider(create: (_) => VCSRepository()),
        Provider(create: (_) => NotificationRepository()),

        // ViewModels
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ContactsBloc(
              context.read<UserRepository>(),
              context.read<NotificationRepository>(),
            ),
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
      navigatorKey: navigatorKey,
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
            final uid = snapshot.data!.uid;

            // Обновление статуса пользователя
            context.read<UserRepository>().setupPresence(uid);

            // Инициализация прослушиваний изменения токена
            _initFcmTokenHandling(context);

            return const HomeView(); // Пользователь залогинен
          }

          return LoginView(); // Пользователь не залогинен
        },
      ),
    );
  }
}

void _initFcmTokenHandling(BuildContext context) async {
  final notificationRepo = context.read<NotificationRepository>();

  // Получаем текущий токен при запуске
  String? token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await notificationRepo.updateTokenInDatabase(token);
  }

  // Подписываемся на обновление токена в будущем
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await notificationRepo.updateTokenInDatabase(newToken);
  });
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

  // Локальное уведомление
  await flutterLocalNotificationsPlugin.initialize(
    settings: const InitializationSettings(
      android: initializationSettingsAndroid,
    ),
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null) {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _handleMessageClick(data);
      }
    },
  );

  // Когда приложение открыто
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
        payload: jsonEncode(message.data),
      );
    }
  });

  // Когда приложение в фоне
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleMessageClick(message.data);
  });

  // Обработка нажатия, когда приложение было полностью закрыто
  RemoteMessage? initialMessage = await FirebaseMessaging.instance
      .getInitialMessage();
  if (initialMessage != null) {
    Future.delayed(const Duration(milliseconds: 500), () {
      _handleMessageClick(initialMessage.data);
    });
  }
}

// Функция обработки клика
void _handleMessageClick(Map<String, dynamic> data) {
  final String? type = data['type'];
  final String? chatId = data['chatId'];

  if (type == 'call_request' && chatId != null) {
    // Переход в конкретный чат
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => ChatBloc(
            chatRepository: context.read<ChatRepository>(),
            userRepository: context.read<UserRepository>(),
          )..add(InitChat(chatId)),
          child: ChatScreen(
            chatId: chatId,
            currentUserId: FirebaseAuth.instance.currentUser!.uid,
          ),
        ),
      ),
    );
  } else {
    // Обычное уведомление — идем в список уведомлений
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => const NotificationsView()),
    );
  }
}
