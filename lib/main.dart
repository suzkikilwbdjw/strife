import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:strife/data/repositories/chat_repository.dart';
import 'package:strife/data/repositories/notification_repository.dart';
import 'package:strife/data/repositories/user_repository.dart';
import 'package:strife/data/repositories/vcs_repository.dart';
// Импорты слоев
import 'package:strife/firebase/firebase_options.dart';
import 'package:strife/presentation/blocs/chats/chat_bloc.dart';
import 'package:strife/presentation/blocs/contacts/contacts_bloc.dart';
import 'package:strife/presentation/blocs/home/home_bloc.dart';
import 'package:strife/presentation/blocs/home/home_event.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/services/notification_service.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/data/repositories/auth_repository.dart';
import 'package:strife/ui/views/chat_screen/chat_screen.dart';

// Импорты экранов
import 'package:strife/ui/views/auth/login_view.dart';
import 'package:strife/ui/views/home/home_view.dart';
import 'package:strife/ui/views/notifications/notifications_view.dart';
import 'package:strife/ui/views/room/room_view.dart';
import 'package:strife/ui/widgets/app_notifications.dart';

// Глобальный ключ навигации
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting('ru');

  // Настройка уведомлений
  await NotificationService.setupNotifications(
    onMessageClick: (data) => _handleMessageClick(data),
    getCurrentChatId: () => ChatScreen.currentOpenChatId,
  );

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
            create: (context) =>
                VCSBloc(vcsRepository: context.read<VCSRepository>()),
          ),
          BlocProvider(create: (context) => NavigationBloc()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<Uri>? _linkSubscriprion;

  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  Future<void> initDeepLinks() async {
    _linkSubscriprion = _appLinks.uriLinkStream.listen((uri) async {
      if (uri.isScheme('strife') && uri.host == 'room') {
        final roomId = uri.queryParameters['id'];

        if (roomId == null) return;
        if (!mounted) return;

        final exists = await context.read<VCSRepository>().checkRoomExists(
          roomId,
        );

        if (exists) {
          debugPrint('Комната существует');
          final User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            if (!mounted) return;
            final vcsBloc = context.read<VCSBloc>();
            vcsBloc.add(
              ConnectRequested(
                roomId: roomId,
                identity: user.uid,
                name: user.displayName!,
                photoUrl: user.photoURL!,
              ),
            );
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) =>
                    BlocProvider.value(value: vcsBloc, child: RoomView()),
              ),
            );
          }
        } else {
          if (!mounted) return;

          // Показываем ошибку пользователю
          AppNotifications.showError(context, 'Получен неверный id комнаты');

          return;
        }
      }
    });
  }

  @override
  void dispose() async {
    super.dispose();
    _linkSubscriprion?.cancel();
  }

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
  } else if (type == 'vcs_session') {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const RoomView()),
    );
  } else {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const NotificationsView()),
    );
  }
}
