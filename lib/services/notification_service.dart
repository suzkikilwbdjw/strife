import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String _isolatePortName = 'vsc_notification_port';

// Фоновые обработчики
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _showNotificationWithAvatar(message);
}

@pragma('vm:entry-point')
void _vcsNotificationHandler(NotificationResponse notificationResponse) {
  if (notificationResponse.notificationResponseType ==
      NotificationResponseType.selectedNotificationAction) {
    final SendPort? sendPort = IsolateNameServer.lookupPortByName(
      _isolatePortName,
    );

    if (sendPort != null && notificationResponse.actionId != null) {
      sendPort.send(notificationResponse.actionId);
    }
  }
}

@pragma('vm:entry-point')
Future<void> _showNotificationWithAvatar(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;
  if (notification == null) return;

  String? photoUrl =
      message.notification?.android?.imageUrl ?? message.data['senderPhotoUrl'];
  AndroidNotificationDetails androidDetails;

  const channel = NotificationService.channel;

  try {
    if (photoUrl != null &&
        photoUrl.isNotEmpty &&
        photoUrl.startsWith('http')) {
      final http.Response response = await http.get(Uri.parse(photoUrl));
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File(
        '${tempDir.path}/avatar_${notification.hashCode}.jpg',
      );
      await file.writeAsBytes(response.bodyBytes);

      final person = Person(
        name: notification.title ?? 'Пользователь',
        key: message.data['senderId'] ?? 'sender',
        icon: BitmapFilePathAndroidIcon(file.path),
      );

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
      androidDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.max,
        priority: Priority.high,
      );
    }
  } catch (e) {
    androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.high,
    );
  }

  await NotificationService.flutterLocalNotificationsPlugin.show(
    id: notification.hashCode,
    title: notification.title,
    body: notification.body,
    notificationDetails: NotificationDetails(android: androidDetails),
    payload: jsonEncode(message.data),
  );
}

class NotificationService {
  // Приватный конструктор
  NotificationService._();

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static ReceivePort? _receivePort;

  // Каналы для android
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Этот канал используется для важных уведомлений.',
    importance: Importance.max,
  );
  static const AndroidNotificationChannel silentChannel =
      AndroidNotificationChannel(
        'vcs_silent_channel',
        'Текущий звонок',
        description:
            'Отображение управления микрофоном и камерой во время звонка',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      );

  static late Function(Map<String, dynamic>) _onMessageClick;

  static Future<void> setupNotifications({
    required Function(Map<String, dynamic>) onMessageClick,
    required String? Function() getCurrentChatId,
  }) async {
    _onMessageClick = onMessageClick;

    await FirebaseMessaging.instance.requestPermission();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Инициализируем плагин локальных уведомлений
    await flutterLocalNotificationsPlugin.initialize(
      settings: const InitializationSettings(
        android: initializationSettingsAndroid,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final Map<String, dynamic> data = jsonDecode(response.payload!);
          _onMessageClick(data);
        }
      },
      onDidReceiveBackgroundNotificationResponse: _vcsNotificationHandler,
    );

    // Создаем каналы на устройстве Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(silentChannel);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Слушаем пуши при открытом приложении
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notificationType = message.data['type'];
      final incomingChatId = message.data['chatId'];

      if (notificationType == 'message_request' &&
          incomingChatId != null &&
          incomingChatId == getCurrentChatId()) {
        return;
      }

      await _showNotificationWithAvatar(message);
    });

    // Клик по пушу в фоне
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _onMessageClick(message.data);
    });

    // Клик по пушу при полностью закрытом приложении
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      _onMessageClick(initialMessage.data);
    }
  }

  static Future<void> showVCSNotification({
    required String title,
    required String body,
    required List<AndroidNotificationAction> actions,
  }) async {
    final AndroidNotificationDetails testAndroidDetails =
        AndroidNotificationDetails(
          silentChannel.id,
          silentChannel.name,
          channelDescription: silentChannel.description,
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          actions: actions,
          ongoing: true,
          autoCancel: false,
          usesChronometer: true,
        );

    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: testAndroidDetails),
      payload: jsonEncode({'type': 'vcs_session'}),
    );
  }

  static Future<void> hideVCSNotification() async {
    await flutterLocalNotificationsPlugin.cancel(id: 0);
  }

  static void listenNotificationActions(
    Function(String actionId) onActionReceived,
  ) {
    if (_receivePort != null) {
      _receivePort!.close();
    }

    _receivePort = ReceivePort();

    IsolateNameServer.removePortNameMapping(_isolatePortName);
    IsolateNameServer.registerPortWithName(
      _receivePort!.sendPort,
      _isolatePortName,
    );

    _receivePort!.listen((message) {
      if (message is String) {
        onActionReceived(message);
      }
    });
  }
}
