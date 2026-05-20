import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:strife/data/repositories/chat_repository.dart';
import 'package:strife/data/repositories/notification_repository.dart';
import 'package:strife/data/repositories/user_repository.dart';
import 'package:strife/data/repositories/vcs_repository.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
// Импорты слоев
import 'package:strife/firebase/firebase_options.dart';
import 'package:strife/presentation/blocs/chats/chat_bloc.dart';
import 'package:strife/presentation/blocs/contacts/contacts_bloc.dart';
import 'package:strife/presentation/blocs/home/home_bloc.dart';
import 'package:strife/presentation/blocs/home/home_event.dart';
import 'package:strife/presentation/blocs/meetings/meetings_bloc.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/data/repositories/auth_repository.dart';
import 'package:strife/ui/views/chat/chat_screen.dart';

// Импорты экранов
import 'package:strife/ui/views/auth/login_view.dart';
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

  await initializeDateFormatting('ru');

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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ContactsBloc(
              context.read<UserRepository>(),
              context.read<NotificationRepository>(),
            ),
          ),

          BlocProvider(
            create: (context) => MeetingsBloc(
              notificationRepository: context.read<NotificationRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) =>
                VCSBloc(vcsRepository: context.read<VCSRepository>()),
          ),
          BlocProvider(
            create: (context) => NavigationBloc(),
            child: const HomeView(),
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
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
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

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _showNotificationWithAvatar(message);
}

Future<void> setupNotifications() async {
  await FirebaseMessaging.instance.requestPermission();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    await _showNotificationWithAvatar(message);
  });

  // Когда приложение в фоне (клик по системному пушу)
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

Future<void> _showNotificationWithAvatar(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;
  if (notification == null) return;

  String? photoUrl =
      message.notification?.android?.imageUrl ?? message.data['senderPhotoUrl'];

  AndroidNotificationDetails androidDetails;

  try {
    // Если ссылка на фото есть и она валидная скачиваем её
    if (photoUrl != null &&
        photoUrl.isNotEmpty &&
        photoUrl.startsWith('http')) {
      //  Скачиваем аватарку
      final http.Response response = await http.get(Uri.parse(photoUrl));
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File(
        '${tempDir.path}/avatar_${notification.hashCode}.jpg',
      );
      await file.writeAsBytes(response.bodyBytes);

      // Создаем объект автора сообщения для MessagingStyle
      final person = Person(
        name: notification.title ?? 'Пользователь',
        key: message.data['senderId'] ?? 'sender',
        icon: BitmapFilePathAndroidIcon(file.path),
      );

      // Настраиваем стиль мессенджера
      final messagingStyle = MessagingStyleInformation(
        person,
        conversationTitle: null,
        messages: [Message(notification.body ?? '', DateTime.now(), person)],
      );

      androidDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: messagingStyle,
      );
    } else {
      // Дефолтный вариант, если фото нет
      androidDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.max,
        priority: Priority.high,
      );
    }
  } catch (e) {
    // Защита на случай ошибки сети при скачивании картинки
    androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.high,
    );
  }

  // Выводим готовое уведомление
  await flutterLocalNotificationsPlugin.show(
    id: notification.hashCode,
    title: notification.title,
    body: notification.body,
    notificationDetails: NotificationDetails(android: androidDetails),
    payload: jsonEncode(message.data),
  );
}

// Функция обработки клика
void _handleMessageClick(Map<String, dynamic> data) {
  final String? type = data['type'];
  final String? chatId = data['chatId'];

  final context = navigatorKey.currentContext;
  if (context == null) return;

  if ((type == 'call_request' || type == 'message_request') && chatId != null) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => ChatBloc(
            chatRepository: context.read<ChatRepository>(),
            userRepository: context.read<UserRepository>(),
            notificationRepository: context.read<NotificationRepository>(),
          )..add(InitChat(chatId)),
          child: ChatScreen(
            chatId: chatId,
            currentUserId: FirebaseAuth.instance.currentUser!.uid,
          ),
        ),
      ),
    );
  } else if (type == 'meeting_request' ||
      type == 'meeting_reminder_request' ||
      type == 'update_meeting_request' ||
      type == 'cancel_meeting_request') {
    // Сбрасываем стек экранов до самого первого
    navigatorKey.currentState?.popUntil((route) => route.isFirst);

    // Меняем вкладку в Блоке на индекс 2
    context.read<NavigationBloc>().add(ChangeTab(2));
  } else {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => const NotificationsView()),
    );
  }
}
