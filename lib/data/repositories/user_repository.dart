import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class UserRepository {
  final _firestore = FirebaseFirestore.instance;

  final String _baseUrl = 'https://seva.danilkin2244.fvds.ru';

  Stream<User?> get userStream => FirebaseAuth.instance.userChanges();

  // Подписка на статус
  StreamSubscription? _presenceSubscription;

  void setupPresence(String uid) {
    _presenceSubscription?.cancel();

    final presenceRef = FirebaseDatabase.instance.ref('status/$uid');
    final connectedRef = FirebaseDatabase.instance.ref('.info/connected');

    _presenceSubscription = connectedRef.onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      if (connected) {
        presenceRef
            .onDisconnect()
            .set({'state': 'offline', 'last_changed': ServerValue.timestamp})
            .then((_) {
              presenceRef.set({
                'state': 'online',
                'last_changed': ServerValue.timestamp,
              });
            });
      }
    });
  }

  Future<void> goOffline(String uid) async {
    // Останавливаем прослушивание коннекта
    await _presenceSubscription?.cancel();
    _presenceSubscription = null;

    // Ставим статус оффлайн
    await FirebaseDatabase.instance.ref('status/$uid').set({
      'state': 'offline',
      'last_changed': ServerValue.timestamp,
    });
  }

  // Обоюдное добавление контакта
  Future<void> acceptFriendRequest({
    required String currentUserId,
    required String contactId,
  }) async {
    try {
      // Сначала достаем актуальные данные обоих юзеров
      final myData = await getUserData(currentUserId);
      final partnerData = await getUserData(contactId);

      final batch = _firestore.batch();

      // Записываем данные партнера в контакты
      batch.set(
        _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('contacts')
            .doc(contactId),
        {
          'email': partnerData['email'],
          'displayName': partnerData['displayName'],
          'photoUrl': partnerData['photoUrl'],
          'addedAt': FieldValue.serverTimestamp(),
          'id': contactId,
        },
        SetOptions(merge: true),
      );

      // Записываем мои данные к нему в контакты
      batch.set(
        _firestore
            .collection('users')
            .doc(contactId)
            .collection('contacts')
            .doc(currentUserId),
        {
          'email': myData['email'],
          'displayName': myData['displayName'],
          'photoUrl': myData['photoUrl'],
          'addedAt': FieldValue.serverTimestamp(),
          'id': currentUserId,
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  // Получение списка ID контактов
  Future<List<String>> getContacts(String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .get();

      // Извлекаем ID документов
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return []; // Возвращаем пустой список при ошибке
    }
  }

  // Удаление обоюдное удаление контакта
  Future<void> removeContact(String currentUserId, String contactId) async {
    try {
      final batch = _firestore.batch();

      // Ссылка на контакт у меня
      final myContactRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(contactId);

      // Ссылка на контакт у него
      final hisContactRef = _firestore
          .collection('users')
          .doc(contactId)
          .collection('contacts')
          .doc(currentUserId);

      batch.delete(myContactRef);
      batch.delete(hisContactRef);

      await batch.commit();
    } catch (e) {
      return;
    }
  }

  // Стрим для отслеживаний изменений
  Stream<List<Map<String, dynamic>>> getContactsStream(String currentUserId) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('contacts')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return {
              'id': doc.data()['id'],
              'isFavorite': doc.data()['isFavorite'] ?? false,
              'displayName': doc.data()['displayName'],
              'photoUrl': doc.data()['photoUrl'],
              'email': doc.data()['email'],
            };
          }).toList(),
        );
  }

  // Получение данных конкретного пользователя
  Future<Map<String, dynamic>> getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data() ?? {};
  }

  // Добавление контакта в избранный
  Future<void> toggleFavorite(
    String currentUserId,
    String contactId,
    bool isFavorite,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(contactId)
          .update({'isFavorite': isFavorite});
    } catch (_) {
      rethrow;
    }
  }

  // Стрим для отслеживания Встреч
  Stream<List<Map<String, dynamic>>> getMeetingsStream(String userId) {
    return _firestore
        .collection('meetings')
        .where('participantIds', arrayContains: userId)
        .orderBy('meetingDateTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }

  // Стрим для отслеживания звонков
  Stream<List<Map<String, dynamic>>> getCallsStream(String userId) {
    return _firestore
        .collection('rooms')
        .where('participantIds', arrayContains: userId)
        .where('type', isEqualTo: 'call')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }

  // Обновление данных встречи
  Future<void> updateMeeting(
    String idMeeting,
    String titleMeeting,
    String dateMeeting,
    String timeMeeting,
    List<String> participantIds,
  ) async {
    try {
      await _firestore.collection('meetings').doc(idMeeting).update({
        titleMeeting: titleMeeting,
        dateMeeting: dateMeeting,
        timeMeeting: timeMeeting,
        participantIds: participantIds,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Обновление отображаемого имени пользователя
  Future<void> updateUserDisplayName(String userId, String newName) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/user/update-name'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'newName': newName}),
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка сервера: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Обновление пароля пользователя
  Future<void> updateUserPassword(
    String oldPassword,
    String newPassword,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) return;

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: oldPassword,
    );

    try {
      //  Подтверждаем, что старый пароль введен верно
      await user.reauthenticateWithCredential(cred);

      // Устанавливаем новый пароль
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (_) {
      rethrow;
    }
  }
}
