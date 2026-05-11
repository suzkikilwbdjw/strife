import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationRepository {
  final String _baseUrl = 'http://62.109.2.27:4000';
  final _firestore = FirebaseFirestore.instance;

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

  // Метод отправки уведомление о добавлении во встречу
  Future<void> sendMeetingRequest({
    required String senderId,
    required List<String> participantIds,
    required String senderName,
    required String senderPhotoUrl,
    required String roomId,
    required String titleMeeting,
    required String dateMeeting,
    required String timeMeeting,
  }) async {
    try {
      // Делаем запрос на бэкэнд
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications/send-meeting-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': senderId,
          'participantIds': participantIds,
          'senderName': senderName,
          'senderPhotoUrl': senderPhotoUrl,
          'roomId': roomId,
          'titleMeeting': titleMeeting,
          'dateMeeting': dateMeeting,
          'timeMeeting': timeMeeting,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка сервера: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
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

  // Удаление уведомления
  Future<void> removeNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      rethrow;
    }
  }
}
