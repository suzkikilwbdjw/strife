import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Регистрация
  Future<UserCredential> register(String email, String password) {
    try {
      return _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (_) {
      rethrow;
    }
  }

  // Вход
  Future<UserCredential> login(String email, String password) {
    try {
      return _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (_) {
      rethrow;
    }
  }

  /// Запись в БД
  Future<void> saveUserData(
    User user, {
    Map<String, dynamic>? extraData,
  }) async {
    // Токен для получения уведомлений
    String? token = await FirebaseMessaging.instance.getToken();

    final data = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'lastSeen': FieldValue.serverTimestamp(),
      if (extraData != null) ...extraData,
      if (token != null) ...{'fcmToken': token},
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }

  // Выход из аккаунта
  Future<void> logout() => _auth.signOut();

  // Вход с помощью яндекса
  Future<UserCredential?> loginWithYandex() async {
    const String clientId = 'eec50519460e457fa6684940520fbfbc';
    const String redirectUri = 'com.example.strife://callback';
    const String backendUrl = 'http://62.109.2.27';

    final appLinks = AppLinks();
    StreamSubscription? linkSubscription;

    // Создаем Completer
    final completer = Completer<UserCredential?>();

    try {
      // 1. Начинаем слушать входящие ссылки
      linkSubscription = appLinks.uriLinkStream.listen((uri) async {
        // Проверяем, что ссылка наша и в ней есть код
        if (uri.scheme == 'com.example.strife' &&
            uri.queryParameters.containsKey('code')) {
          final code = uri.queryParameters['code'];

          try {
            // 2. Обмен кода на токен
            final response = await http.post(
              Uri.parse('$backendUrl:4000/auth/yandex'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'code': code}),
            );

            if (response.statusCode != 200) {
              throw Exception("Backend failed: ${response.body}");
            }

            final data = jsonDecode(response.body);
            final String firebaseToken = data['firebaseToken'];

            // 3. Вход в Firebase
            final userCredential = await FirebaseAuth.instance
                .signInWithCustomToken(firebaseToken);

            if (!completer.isCompleted) completer.complete(userCredential);
          } catch (e) {
            if (!completer.isCompleted) completer.complete(null);
          }
        }
      });

      // 2. Формируем URL для авторизации
      final authUrl = Uri.https('oauth.yandex.ru', '/authorize', {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
      });

      // 3. Открываем браузер.
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);

      return await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          return null;
        },
      );
    } catch (e) {
      return null;
    } finally {
      await linkSubscription?.cancel();
    }
  }
}
