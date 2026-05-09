import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получения потока сообщений
  Stream<List<MessageModel>> getMessage(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Отправка сообщений
  Future<void> sendMessage(String chatId, MessageModel message) async {
    try {
      final batch = _firestore.batch();

      // Ссылка на новое сообщение
      DocumentReference messageReference = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      // Ссылка на чат
      DocumentReference chatReference = _firestore
          .collection('chats')
          .doc(chatId);

      batch.set(messageReference, message.toFirestore());

      batch.set(chatReference, {
        'lastMessage': message.text,
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  // Создание или получение id личного чата, вне комнаты
  Future<String> getOrCreatePrivateChatId(String myId, String partnerId) async {
    List<String> ids = [myId, partnerId]..sort();

    String chatId = ids.join('_');

    DocumentSnapshot chatDocument = await _firestore
        .collection('chats')
        .doc(chatId)
        .get();

    if (!chatDocument.exists) {
      ChatModel newChat = ChatModel(
        id: chatId,
        type: ChatType.private,
        participants: ids,
      );

      await _firestore
          .collection('chats')
          .doc(chatId)
          .set(newChat.toFirestore());
    }

    return chatId;
  }

  // Пометка сообщений прочитанными
  Future<void> markAsRead(String chatId, String userId) async {
    final query = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId) // Берем только чужие сообщения
        .orderBy('timestamp', descending: true)
        .limit(10) // Проверяем только последние 10 сообщений
        .get();

    final batch = _firestore.batch();

    for (var doc in query.docs) {
      List readBy = doc.data()['readBy'] ?? [];
      if (!readBy.contains(userId)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([
            userId,
          ]), // Добавляем наш ID в список
        });
      }
    }

    await batch.commit();
  }

  Future<void> syncRoomChat(
    String liveKitRoomId,
    List<String> participantIds,
  ) async {
    DocumentReference chatReference = _firestore
        .collection('chats')
        .doc(liveKitRoomId);

    await chatReference.set({
      'type': 'room',
      'liveKitRoomId': liveKitRoomId,
      'participants': FieldValue.arrayUnion(participantIds),
      'lastUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Подтягивает все чаты в которых я участник
  Stream<List<Map<String, dynamic>>> getAllMyChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastUpdate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }
}
