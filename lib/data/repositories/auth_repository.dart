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
  Future<UserCredential> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (_) {
      rethrow;
    }
  }

  /// Запись в БД
  Future<void> saveUserData(
    User user, {
    Map<String, dynamic>? extraData,
  }) async {
    // Получаем ссылку на документ пользователя
    final userDocRef = _firestore.collection('users').doc(user.uid);

    // Проверяем, существует ли документ
    final docSnapshot = await userDocRef.get();
    final bool docExists = docSnapshot.exists;

    // Получаем FCM-токен
    String? token = await FirebaseMessaging.instance.getToken();

    // Собираем map данных
    final data = <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'lastSeen': FieldValue.serverTimestamp(),
      if (extraData != null) ...extraData,
      if (token != null) ...{'fcmToken': token},
    };

    // Добавляем имя и фото только если документа еще нет в базе
    if (!docExists) {
      data['displayName'] = user.displayName;
      data['photoUrl'] = user.photoURL;
    }

    // Записываем данные
    await userDocRef.set(data, SetOptions(merge: true));
  }

  // Выход из аккаунта
  Future<void> logout() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      // Удаляем токен перед выходом
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
    }

    await _auth.signOut();
  }

  // Вход с помощью яндекса
  Future<UserCredential?> loginWithYandex() async {
    const String clientId = 'eec50519460e457fa6684940520fbfbc';
    const String redirectUri = 'com.example.strife://callback';
    const String backendUrl = 'https://seva.danilkin2244.fvds.ru';

    final appLinks = AppLinks();
    StreamSubscription? linkSubscription;
    final completer = Completer<UserCredential?>();

    try {
      linkSubscription = appLinks.uriLinkStream.listen((uri) async {
        if (uri.scheme == 'com.example.strife' &&
            uri.queryParameters.containsKey('code')) {
          final code = uri.queryParameters['code'];

          try {
            final response = await http.post(
              Uri.parse('$backendUrl/auth/yandex'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'code': code}),
            );

            if (response.statusCode != 200) {
              throw Exception("Backend failed: ${response.body}");
            }

            final data = jsonDecode(response.body);
            final String firebaseToken = data['firebaseToken'];

            // Получаем имя и фото, которые прислал бэкенд
            final String? yandexName = data['displayName'];
            final String? yandexPhoto = data['photoURL'];

            // Авторизуемся в Firebase
            final userCredential = await FirebaseAuth.instance
                .signInWithCustomToken(firebaseToken);

            final user = userCredential.user;

            if (user != null) {
              if (user.displayName == null && yandexName != null) {
                await user.updateDisplayName(yandexName);
              }
              if (user.photoURL == null && yandexPhoto != null) {
                await user.updatePhotoURL(yandexPhoto);
              }
              // Перезагружаем данные пользователя, чтобы изменения применились
              await user.reload();
            }

            if (!completer.isCompleted) completer.complete(userCredential);
          } catch (e) {
            if (!completer.isCompleted) completer.complete(null);
          }
        }
      });

      final authUrl = Uri.https('oauth.yandex.ru', '/authorize', {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
      });

      await launchUrl(authUrl, mode: LaunchMode.externalApplication);

      return await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => null,
      );
    } catch (e) {
      return null;
    } finally {
      await linkSubscription?.cancel();
    }
  }
}
