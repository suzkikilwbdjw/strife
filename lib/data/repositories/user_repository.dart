import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserRepository {
  final _firestore = FirebaseFirestore.instance;
  final String _baseUrl = 'http://62.109.2.27:4000';

  // Метод для отправки запроса в звонок
  Future<void> sendCallRequest({
    required String senderId,
    required String recipientId,
    required String senderName,
    required String senderPhotoUrl,
    required String roomId,
  }) async {
    try {
      // Делаем запрос на бэкэнд
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications/send-call-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': senderId,
          'recipientId': recipientId,
          'senderName': senderName,
          'senderPhotoUrl': senderPhotoUrl,
          'roomId': roomId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка сервера: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Метод для отправки запроса в контакты
  Future<void> sendFriendRequest({
    required String senderId,
    required String recipientEmail,
    required String senderName,
    required String senderPhotoUrl,
  }) async {
    try {
      //  Ищем ID получателя
      final userSnap = await _firestore
          .collection('users')
          .where('email', isEqualTo: recipientEmail)
          .get();

      if (userSnap.docs.isEmpty) {
        throw Exception('Пользователь с таким email не найден');
      }

      final recipientId = userSnap.docs.first.id;

      // Делаем запрос на бэкэнд
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications/send-friend-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': senderId,
          'recipientId': recipientId,
          'senderName': senderName,
          'senderPhotoUrl': senderPhotoUrl,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка сервера: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Обоюдное добавление контакта
  Future<void> addContact(String currentUserId, String contactId) async {
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

      batch.set(myContactRef, {
        'addedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(hisContactRef, {
        'addedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (_) {
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
  Stream<List<Map<String, dynamic>>> contactsStream(String currentUserId) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('contacts')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              'isFavorite': doc.data()['isFavorite'] ?? false,
            };
          }).toList(),
        );
  }

  // Стрим для отслеживания уведомлений
  Stream<List<Map<String, dynamic>>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
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

  // Загрузка инфы о пользователи по id
  Future<Map<String, dynamic>> getUser(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data()!;
      } else {
        return {};
      }
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  // Удаление уведомления
  Future<void> removeNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      rethrow;
    }
  }
}
