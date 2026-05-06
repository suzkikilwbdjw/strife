import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserRepository {
  final _firestore = FirebaseFirestore.instance;
  final String _baseUrl = 'http://62.109.2.27:4000';

  // Метод для отправки запроса через бэкэнд
  Future<void> sendFriendRequest({
    required String recipientEmail,
    required String senderName,
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
          'recipientId': recipientId,
          'senderName': senderName,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка сервера: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Добавление контакта
  Future<void> addContact(String currentUserId, String contactId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(contactId)
          .set({
            'addedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {
      return;
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

  // Удаление контакта
  Future<void> removeContact(String currentUserId, String contactId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(contactId)
          .delete();
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
}
